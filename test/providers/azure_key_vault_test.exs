defmodule ExSecrets.Providers.AzureKeyVaultTest do
  use ExUnit.Case

  alias ExSecrets.Providers.AzureKeyVault
  alias ExSecrets.AzureKeyVaultHTTPAdapterMock
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

    Application.put_env(:ex_secrets, :http_adapter, AzureKeyVaultHTTPAdapterMock)
    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
    Mox.defmock(ExSecrets.AzureKeyVaultHTTPAdapterMock, for: ExSecrets.HTTPAdapterBehavior)

    {:ok, %{}}
  end

  test "Get Secret Azure Key Vault with and without cache" do
     AzureKeyVaultHTTPAdapterMock
    # Token API Call - 2
    |> expect(:post, &get_token_mock/3)
    |> expect(:post, &get_token_mock/3)
    # Secret API Calls - 2
    |> expect(:get, &get_secret_mock/2)
    |> expect(:get, &get_secret_mock/2)

    assert ExSecrets.get("ABC-1", :azure_key_vault) == "VAL"
    assert ExSecrets.get("ABC-2", :azure_key_vault) == "VAL"
    assert ExSecrets.get("ABC-2", :azure_key_vault) == "VAL"

    AzureKeyVaultHTTPAdapterMock
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

    {:ok, _} = AzureKeyVault.start_link([])

    # 1st call to get secret - API
    assert ExSecrets.get("KEY-1", :azure_key_vault) == "VAL"
    # 2nd call to get secret - Cache
    assert ExSecrets.get("KEY-1", :azure_key_vault) == "VAL"
    # 3rd call to get secret - API
    assert ExSecrets.get("KEY-2", :azure_key_vault) == "VAL"
    # 4th call to get secret - API
    assert ExSecrets.get("KEY-3", :azure_key_vault) == "VAL"

    # 5th call to get secret - API
    Application.put_env(:ex_secrets, :on_secret_fetch_limit_reached, :raise)
    Application.put_env(:ex_secrets, :secret_fetch_limit, 4)

    # 4 calls with nil
    assert ExSecrets.get("NULL", :azure_key_vault) == nil
    assert ExSecrets.get("NULL", :azure_key_vault) == nil
    assert ExSecrets.get("NULL", :azure_key_vault) == nil
    assert ExSecrets.get("NULL", :azure_key_vault) == nil
    assert ExSecrets.get("NULL", :azure_key_vault) == nil

    assert_raise RuntimeError, ~r/^Fetch secret NULL reached limit 4/, fn ->
      assert ExSecrets.get("NULL", :azure_key_vault) == nil
    end

    assert_raise RuntimeError, ~r/^Fetch secret NULL reached limit 4/, fn ->
      assert ExSecrets.get("NULL", :azure_key_vault) == nil
    end

    verify!(AzureKeyVaultHTTPAdapterMock)
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
    case String.contains?(url, "NULL") do
      true -> {:ok, %HTTPoison.Response{body: "{}", status_code: 200}}
      false -> {:ok, %HTTPoison.Response{body: "{\"value\":\"VAL\"}", status_code: 200}}
    end
  end
end
