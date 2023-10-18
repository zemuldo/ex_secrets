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
        service_account: %{
          "type" => "service_account",
          "project_id" => "test",
          "private_key_id" => "test123",
          "private_key" =>
            "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDpqU2PXKm08Png\nhgYHu6VN/GAmvrBCoXmCO68WPSBx5la3JI0lSyf3uW9AXzzfe6ApP08xYS9WVGUN\n8xgFLJnVMjA+MhUaZ0AGmiE2bp1qWwkOxKaWf+Ynh0xwS7p7tIcE9CHU1KcArgfE\nAjwQxs/DbgXYUdNTOAbTeP4CLpSxh8SiZpqQ2egCPjNVHWePCPlkOp9s1pDjSktb\nH4O6CiZZ6bS1/7mQ2erzfzzG9w7l1aPLcfDQLHtXcFzXkSvOVhXwIaS3fS4+lf/4\ndXFzinbahbyitfL6uaItBrluFvotAA5nv1Z3Pc0o+4t8PThmLCKP6T5cBvWOc81K\nlQ23LPd/AgMBAAECggEACmzPVRIhUD1gKLBSHI42teAIujHP02k47qKTET7w76QD\nQnCTC5Lq2ZagbBLTuHTflHeKpP1dC1EAoTqzW6e9xVFT7bJ2VpM8vA6sZK1SwKgH\nI22KsTRLpH/Y3TnDvDk1vPbXe5NxUApztj8TRvxX0LRb9mbQMupRA6ZmTtqdL751\nJYdhBbrqiNE97r66BPx8fEmP+797dtSaRRSilX29TqtX2C7xnrk0LyO8tnwd9anV\n2/zBRNu44qQufeVojrFKdAL+Thfgt664zZgzP7NeuTL4X94BOnogH7IcGUEa9sB7\nGxZ5xhIBrYrYNXAmoZjLezi023q6cqq9pXrGQeQ3YQKBgQD8nGlaJuSnxiIO3Qn9\n4hccAWTA3vHn5AIaInl9Z0sZGm/83ct2uE371XDr26hwVVmqVWaanG8EXtF+zwia\npnCudrUXsV2P8QbSBhWBGCsa1NykbVg9q+dU2n0W7JhFbhwZFbd4g+3TjNCd1Gor\nkQ2GtbOugXt2mikaD0ls/1j1ZQKBgQDsy88mwHbNvbSXVmX+ibRzNMd8u3d3EMlS\nV+mkx6+/d3OLaPHqGRZcWfKprT+Fiz/H7C9MQU+ypjqcA0oEA6nE3XTAwlfBXKrN\nnNY8AoqSmrMc3OfxgEHKL6v5D+xNGPEaet3EVnCQ8CvTXYynHraA4pkDZ7bAq7H7\ntG34j7AtEwKBgGBP1k8cAxQAk92s4vFccUkpMtviZMLwCOkj+cQZTOWuUcJMYhXK\noVkCAQK8BhWGRSCPXQZX3HADIsbBcttb2Bx8gAEfi7ekwt/yl+JXb5/URqeeVQV2\ndEXC4+yImmnmWGosAH6/dj6xMpzqbuxbapfQ0UgYcBVBI6ie6XTYSneNAoGAT7MB\nU/+vfOv+3nj790IN9ECta/QE75Q8znQ8dXOoWX8w6pk14x7ygb7ch/OBz8bgfr+l\n47qPwodkbqJExTkeaN5Ir6A5vSEdc/r3uFb6oQFki7BmeMg8XHrTHQ8Y75IXhFwa\nTDzzwjSz634vGwihUJvz+EtuHUcsrpU59lEWcPUCgYEAkUhT9yfA47Wfc9Pv3vS5\n5dYm2QHfEU0RhOozY6DKMJs60zsysp6XFBg0vpKJXa8/Q7gFXz6wd+kYJsGUc6lo\ncfVt3fXFLNqnOxYKZOU+T41qhASOXdSM/OR5OJ7m8kYepEhKIuXxlVNxO8reNnm5\nWJ9lbCurW3dM5ol4DgCKaak=\n-----END PRIVATE KEY-----\n",
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
