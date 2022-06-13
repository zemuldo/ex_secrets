defmodule ExSecrets.Providers.AzureKeyVaultTest do
  use ExUnit.Case

  alias ExSecrets.Providers.AzureKeyVault
  alias ExSecrets.HTTPAdapterMock
  doctest ExSecrets

  import Mox

  setup :set_mox_global

  setup do
    Application.put_env(:ex_secrets, :providers, %{
      azure_key_vault: %{
        tenant_id: "tenant-id",
        client_id: "client-id",
        client_secret: "client-secret",
        key_vault_name: "key-vault-name"
      }
    })

    Application.put_env(:ex_secrets, :http_adapter, HTTPAdapterMock)
    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
    {:ok, %{}}
  end

  test "Get Secret from Azure KV" do
    HTTPAdapterMock
    |> expect(:post, fn url, body, _ ->
      assert url == "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token"

      assert body ==
               "client_id=client-id&client_secret=client-secret&grant_type=client_credentials&scope=https%3A%2F%2Fvault.azure.net%2F.default"

      {:ok,
       %HTTPoison.Response{
         body:
           "{\"token_type\":\"Bearer\",\"expires_in\":3599,\"ext_expires_in\":3599,\"access_token\":\"dummy_access_token\"}",
         request_url: "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token",
         status_code: 200
       }}
    end)
    |> expect(:post, fn url, body, _ ->
      assert url == "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token"

      assert body ==
               "client_id=client-id&client_secret=client-secret&grant_type=client_credentials&scope=https%3A%2F%2Fvault.azure.net%2F.default"

      {:ok,
       %HTTPoison.Response{
         body:
           "{\"token_type\":\"Bearer\",\"expires_in\":3599,\"ext_expires_in\":3599,\"access_token\":\"dummy_access_token\"}",
         request_url: "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token",
         status_code: 200
       }}
    end)
    |> expect(:get, fn url, _ ->
      assert url ==
               "https://key-vault-name.vault.azure.net/secrets/ABC?api-version=2016-10-01"

      {:ok,
       %HTTPoison.Response{
         body: "{\"value\":\"DOTXYZHASH\"}",
         status_code: 200
       }}
    end)

    {:ok, _} = GenServer.start(AzureKeyVault, [], name: AzureKeyVault)

    assert ExSecrets.get("ABC", :azure_key_vault) == "DOTXYZHASH"
  end
end
