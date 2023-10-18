defmodule ExSecrets.Providers.AzureKeyManagedIdentityTest do
  use ExUnit.Case

  alias ExSecrets.Providers.AzureManagedIdentity
  alias ExSecrets.HTTPAdapterMock
  doctest ExSecrets

  import Mox
  setup :set_mox_global

  setup do
    Application.put_env(:ex_secrets, :providers, %{
      azure_managed_identity: %{
        key_vault_name: "KKEYvault-name"
      }
    })

    Application.put_env(:ex_secrets, :http_adapter, HTTPAdapterMock)
    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
    Mox.defmock(ExSecrets.HTTPAdapterMock, for: ExSecrets.HTTPAdapterBehavior)

    {:ok, %{}}
  end

  test "Get Secret Azure Managed Identity with and without cache" do
    HTTPAdapterMock
    # Token API Call
    |> expect(:get, &get_token_mock/2)
    # Secret API Call
    |> expect(:get, &get_secret_mock/2)

    assert ExSecrets.get("ABCXYZ", :azure_managed_identity) == "VAL"
    assert ExSecrets.get("ABCXYZ", :azure_managed_identity) == "VAL"

    verify!(HTTPAdapterMock)

    HTTPAdapterMock
    # Token API Call
    |> expect(:get, &get_token_mock/2)
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

    {:ok, _} = AzureManagedIdentity.start_link([])

    # 1st call to get secret - API
    assert ExSecrets.get("KKEY1", :azure_managed_identity) == "VAL"
    # 2nd call to get secret - Cache
    assert ExSecrets.get("KKEY1", :azure_managed_identity) == "VAL"
    # 3rd call to get secret - API
    assert ExSecrets.get("KKEY2", :azure_managed_identity) == "VAL"
    # 4th call to get secret - API
    assert ExSecrets.get("KKEY3", :azure_managed_identity) == "VAL"

    # 5th call to get secret - API
    Application.put_env(:ex_secrets, :on_secret_fetch_limit_reached, :raise)
    Application.put_env(:ex_secrets, :secret_fetch_limit, 4)

    # 9 more calls with nil
    assert ExSecrets.get("NULLL", :azure_managed_identity) == nil
    assert ExSecrets.get("NULLL", :azure_managed_identity) == nil
    assert ExSecrets.get("NULLL", :azure_managed_identity) == nil
    assert ExSecrets.get("NULLL", :azure_managed_identity) == nil
    assert ExSecrets.get("NULLL", :azure_managed_identity) == nil

    assert_raise RuntimeError, ~r/^Fetch secret NULLL reached limit 4/, fn ->
      assert ExSecrets.get("NULLL", :azure_managed_identity) == nil
    end

    assert_raise RuntimeError, ~r/^Fetch secret NULLL reached limit 4/, fn ->
      assert ExSecrets.get("NULLL", :azure_managed_identity) == nil
    end

    verify!(HTTPAdapterMock)
  end

  defp get_token_mock(_url, _) do
    {:ok,
     %HTTPoison.Response{
       body: "{\"expires_in\":3599,\"ext_expires_in\":3599,\"access_token\":\"dummy\"}",
       request_url: "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token",
       status_code: 200
     }}
  end

  defp get_secret_mock(url, _data) do
    case String.contains?(url, "NULLL") do
      true -> {:ok, %HTTPoison.Response{body: "{}", status_code: 200}}
      false -> {:ok, %HTTPoison.Response{body: "{\"value\":\"VAL\"}", status_code: 200}}
    end
  end
end
