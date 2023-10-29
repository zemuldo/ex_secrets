defmodule ExSecrets.Providers.AzureManagedIdentity do
  use ExSecrets.Providers.Base

  alias ExSecrets.Utils.Config

  @moduledoc """
  Azure Key Vault provider provides secrets from an Azure Key Vault through a rest API.

  Only the keyvault name is required here once the managed identity has been given access to the keyvault.

  ```
      config :ex_secrets, :providers, %{
         azure_managed_identity: %{
         key_vault_name: "key-vault-name"
      }
  ```

  The provider will handle token renewals and secret fetch.
  """

  @headers %{"Content-Type" => "application/x-www-form-urlencoded", "Metadata" => "true"}
  @process_name :ex_secrets_azure_managed_identity

  def init(_) do
    case get_access_token() do
      {:ok, data} ->
        {:ok, data |> Map.put("issued_at", get_current_epoch())}

      _ ->
        {:ok, %{}}
    end
  end

  def reset() do
    :ok
  end

  def get(name) do
    name = name |> String.split("_") |> Enum.join("-")

    with process when not is_nil(process) <-
           GenServer.whereis(@process_name) do
      GenServer.call(@process_name, {:get, name})
    else
      nil ->
        case get_secret(name, %{}, nil) do
          {:ok, value, _} -> value
          _ -> nil
        end
    end
  end

  def set(name, value) do
    name = name |> String.split("_") |> Enum.join("-")

    with process when not is_nil(process) <-
           GenServer.whereis(@process_name) do
      GenServer.call(@process_name, {:set, name, value})
    else
      nil ->
        case set_secret(name, value, %{}, nil) do
          {:ok, _value, _} ->
            :ok

          _ ->
            :error
        end
    end
  end

  def handle_call({:get, name}, _from, state) do
    case get_secret(name, state, get_current_epoch()) do
      {:ok, secret, state} -> {:reply, secret, state}
      _ -> {:reply, nil, state}
    end
  end

  def handle_call({:set, name, value}, _from, state) do
    case set_secret(name, value, state, get_current_epoch()) do
      {:ok, _secret, state} -> {:reply, :ok, state}
      _ -> {:reply, :error, state}
    end
  end

  defp token_uri() do
    "http://169.254.169.254/metadata/identity/oauth2/token"
    |> Kernel.<>("?api-version=2018-02-01&resource=https://vault.azure.net")
  end

  defp get_secret(
         name,
         %{"access_token" => access_token, "issued_at" => issued_at, "expires_in" => expires_in} =
           state,
         current_time
       )
       when issued_at + expires_in - current_time > 5 do
    with {:ok, value} <- get_secret_call(name, access_token),
         true <- is_binary(value) do
      {:ok, value, state}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret(name, state, _) do
    with {:ok, %{"access_token" => access_token} = new_state} <- get_access_token(),
         {:ok, value} <- get_secret_call(name, access_token) do
      {:ok, value, state |> Map.merge(new_state)}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  def set_secret(
        name,
        value,
        %{"access_token" => access_token, "issued_at" => issued_at, "expires_in" => expires_in} =
          state,
        current_time
      )
      when issued_at + expires_in - current_time > 5 do
    with {:ok, value} <- set_secret_call(name, value, access_token),
         true <- is_binary(value) do
      {:ok, value, state}
    else
      err ->
        err
    end
  end

  def set_secret(name, value, state, _) do
    with {:ok, %{"access_token" => access_token} = new_state} <-
           get_access_token(),
         {:ok, value} <- set_secret_call(name, value, access_token) do
      {:ok, value, state |> Map.merge(new_state) |> Map.put("issued_at", get_current_epoch())}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret_call(name, access_token) do
    client = http_adpater()

    with {:ok, %{body: body, status_code: 200}} <-
           name
           |> secret_url()
           |> client.get(%{"Authorization" => "Bearer #{access_token}"}),
         {:ok, %{"value" => value}} <- Poison.decode(body) do
      {:ok, value}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp set_secret_call(name, value, access_token) do
    client = http_adpater()

    with {:ok, %{body: body, status_code: 200}} <-
           name
           |> secret_url()
           |> client.put(Poison.encode!(%{value: value}), %{
             "Authorization" => "Bearer #{access_token}",
             "content-type" => "application/json"
           }),
         {:ok, %{"value" => value}} <- Poison.decode(body) do
      {:ok, value}
    else
      err -> err
    end
  end

  defp get_access_token() do
    client = http_adpater()

    with {:ok, %{body: body, status_code: 200}} <-
           token_uri()
           |> client.get(@headers),
         {:ok, data} <- Poison.decode(body) do
      {:ok, data |> Map.put("issued_at", get_current_epoch())}
    else
      _ ->
        {:error, "Failed to get access token"}
    end
  end

  defp get_current_epoch() do
    System.system_time(:second)
  end

  defp http_adpater() do
    Application.get_env(:ex_secrets, :http_adapter, HTTPoison)
  end

  defp secret_url(name) do
    key_vault_name = Config.provider_config_value(:azure_managed_identity, :key_vault_name)
    "https://#{key_vault_name}.vault.azure.net/secrets/#{name}?api-version=2016-10-01"
  end

  def process_name() do
    @process_name
  end
end
