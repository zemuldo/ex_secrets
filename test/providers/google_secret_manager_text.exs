defmodule ExSecrets.Providers.GoogleSecretManagerTest do
  use ExUnit.Case

  alias ExSecrets.Providers.GoogleSecretManager
  alias ExSecrets.HTTPAdapterMock
  doctest ExSecrets

  import Mox
  setup :set_mox_global

  setup do
    Application.put_env(:ex_secrets, :providers, %{
      google_secret_manager: %{
        service_account_credentials: %{
          "type" => "service_account",
          "project_id" => "test",
          "private_key_id" => "test123",
          "private_key" =>
            "-----BEGIN PRIVATE KEY-----...-----END PRIVATE KEY-----\n",
          "client_email" => "test@test.iam.gserviceaccount.com",
          "client_id" => "test",
          "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
          "token_uri" => "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url" =>
            "https://www.googleapis.com/robot/v1/metadata/x509/test%40test.iam.gserviceaccount.com",
          "universe_domain" => "googleapis.com"
        }
      }
    })

    Application.put_env(:ex_secrets, :http_adapter, HTTPAdapterMock)
    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
    Mox.defmock(ExSecrets.HTTPAdapterMock, for: ExSecrets.HTTPAdapterBehavior)

    {:ok, %{}}
  end

  test "Get Secret Google Secret Manager with and without cache" do
    HTTPAdapterMock
    # Token API Call
    |> expect(:post, &get_token_mock/3)
    # Secret API Call
    |> expect(:get, &get_secret_mock/2)

    assert ExSecrets.get("ABCXYZ", :google_secret_manager) == "db.mydomain.com"
    assert ExSecrets.get("ABCXYZ", :google_secret_manager) == "db.mydomain.com"
    verify!(HTTPAdapterMock)

    HTTPAdapterMock
    # Token API Call
    |> expect(:post, &get_token_mock/3)
    # Secret API Call
    |> expect(:get, &get_secret_mock/2)
    # Secret API Call
    |> expect(:get, &get_secret_mock/2)
    # Secret API Call
    |> expect(:get, &get_secret_mock/2)
    # Calls that can increase cost: Limited to
    |> expect(:get, &get_secret_mock/2)
    |> expect(:get, &get_secret_mock/2)
    |> expect(:get, &get_secret_mock/2)
    |> expect(:get, &get_secret_mock/2)
    |> expect(:get, &get_secret_mock/2)

    {:ok, _} = GoogleSecretManager.start_link([])

    # 1st call to get secret - API
    assert ExSecrets.get("KKEY1", :google_secret_manager) == "db.mydomain.com"
    # 2nd call to get secret - Cache
    assert ExSecrets.get("KKEY1", :google_secret_manager) == "db.mydomain.com"
    # 3rd call to get secret - API
    assert ExSecrets.get("KKEY2", :google_secret_manager) == "db.mydomain.com"
    # 4th call to get secret - API
    assert ExSecrets.get("KKEY3", :google_secret_manager) == "db.mydomain.com"

    # 5th call to get secret - API
    Application.put_env(:ex_secrets, :on_secret_fetch_limit_reached, :raise)
    Application.put_env(:ex_secrets, :secret_fetch_limit, 4)

    # 9 more calls with nil
    assert ExSecrets.get("NULLL", :google_secret_manager) == nil
    assert ExSecrets.get("NULLL", :google_secret_manager) == nil
    assert ExSecrets.get("NULLL", :google_secret_manager) == nil
    assert ExSecrets.get("NULLL", :google_secret_manager) == nil
    assert ExSecrets.get("NULLL", :google_secret_manager) == nil

    assert_raise RuntimeError, ~r/^Fetch secret NULLL reached limit 4/, fn ->
      assert ExSecrets.get("NULLL", :google_secret_manager) == nil
    end

    assert_raise RuntimeError, ~r/^Fetch secret NULLL reached limit 4/, fn ->
      assert ExSecrets.get("NULLL", :google_secret_manager) == nil
    end

    verify!(HTTPAdapterMock)
  end

  defp get_token_mock(_url, _, _) do
    {:ok,
     %HTTPoison.Response{
       body: "{\"expires_in\":3599,\"ext_expires_in\":3599,\"access_token\":\"dummy\"}",
       request_url: "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token",
       status_code: 200
     }}
  end

  defp get_secret_mock(url, _data) do
    case String.contains?(url, "NULLL") do
      true ->
        {:ok, %HTTPoison.Response{body: "{}", status_code: 200}}

      false ->
        {:ok,
         %HTTPoison.Response{
           body: valid_secret_access_resp() |> Poison.encode!(),
           status_code: 200
         }}
    end
  end

  defp valid_secret_access_resp() do
    %{
      "name" => "projects/test/secrets/ABCXYZ/versions/1",
      "payload" => %{
        "data" => "ZGIubXlkb21haW4uY29t",
        "dataCrc32c" => "3375731831"
      }
    }
  end
end
