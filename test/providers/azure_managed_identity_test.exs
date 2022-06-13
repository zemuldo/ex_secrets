defmodule ExSecrets.Providers.AzureKeyManagedIdentityTest do
  use ExUnit.Case

  alias ExSecrets.Providers.AzureManagedIdentity
  alias ExSecrets.AzureManagedIdentityHTTPAdapterMock
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

    Application.put_env(:ex_secrets, :http_adapter, AzureManagedIdentityHTTPAdapterMock)
    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
    Mox.defmock(ExSecrets.AzureManagedIdentityHTTPAdapterMock, for: ExSecrets.HTTPAdapterBehavior)

    {:ok, %{}}
  end

  test "Get Secret Azure Managed Identity" do
    AzureManagedIdentityHTTPAdapterMock
    |> expect(
      :get,
      fn "http://169.254.169.254" <> _,
         _ ->
        {:ok,
         %HTTPoison.Response{
           body:
             "{\"token_type\":\"Bearer\",\"expires_in\":3599,\"ext_expires_in\":3599,\"access_token\":\"dummy_access_token\"}",
           request_url:
             "https://login.microsoftonline.com/9fb676fa-7f2c-4b77-9de7-9b9d1b56db3f/oauth2/v2.0/token",
           status_code: 200
         }}
      end
    )
    |> expect(:get, fn "https://key-vault-name.vault.azure.ne" <> _, _ ->
      {:ok,
       %HTTPoison.Response{
         body: "{\"value\":\"DOTXYZHASH\"}",
         status_code: 200
       }}
    end)

    {:ok, _} = GenServer.start(AzureManagedIdentity, [], name: AzureManagedIdentity)

    assert ExSecrets.get("ABC", :azure_managed_identity) == "DOTXYZHASH"
  end
end
