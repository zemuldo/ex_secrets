defmodule ExSecrets.Providers.AzureKeyManagedIdentityTest do
  use ExUnit.Case

  alias ExSecrets.Providers.AzureManagedIdentity
  alias ExSecrets.AzureManagedIdentityHTTPAdapterMock
  doctest ExSecrets

  import Mox
  setup :set_mox_global

  setup do
    Application.put_env(:ex_secrets, :providers, %{
      azure_managed_identity: %{
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
    |> expect(:get, &api_mock/2)
    |> expect(:get, &api_mock/2)
    |> expect(:get, &api_mock/2)

    {:ok, _} = GenServer.start(AzureManagedIdentity, [], name: AzureManagedIdentity)

    assert ExSecrets.get("ABC", :azure_managed_identity) == "DOTXYZHASH"
    assert ExSecrets.get("ABC", :azure_managed_identity) == "DOTXYZHASH"
  end

  defp api_mock(url, _) do
    case url do
      "http://169.254.169.254" <> _ ->
        {:ok,
         %HTTPoison.Response{
           body:
             "{\"token_type\":\"Bearer\",\"expires_in\":3599,\"ext_expires_in\":3599,\"access_token\":\"dummy_access_token\"}",
           request_url:
             "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token",
           status_code: 200
         }}

      "https://key-vault-name.vault.azure.net" <> _ ->
        {:ok,
         %HTTPoison.Response{
           body: "{\"value\":\"DOTXYZHASH\"}",
           status_code: 200
         }}
    end
  end
end
