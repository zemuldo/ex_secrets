defmodule ExSecrets.Providers.AzureManagedIdentity do
  use ExSecrets.Providers.Base

  alias ExSecrets.Providers.Config

  @moduledoc """
  Azure Key Vault provider provides secrets from an Azure Key Vault through a rest API.
  """

  @headers %{"Content-Type" => "application/x-www-form-urlencoded", "Metadata" => "true"}

  def init(_) do
    case get_access_token() do
      {:ok, data} ->
        {:ok, data}

      _ ->
        {:ok, %{}}
    end
  end

  def get(name) do
    name = name |> String.split("_") |> Enum.join("-")

    with process when not is_nil(process) <-
           GenServer.whereis(process_name()) do
      GenServer.call(process_name(), {:get, name})
    else
      nil ->
        case get_secret(name, %{}, nil) do
          {:ok, value, _} -> value
          _ -> nil
        end
    end
  end

  def handle_call({:get, name}, _from, state) do
    case get_secret(name, state, get_current_epoch()) do
      {:ok, secret, state} -> {:reply, secret, state}
      _ -> {:reply, nil, state}
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
       when issued_at + expires_in - current_time > 3500 do
    with {:ok, value} <- get_secret_call(name, access_token) do
      {:ok, value, state}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret(name, state, _) do
    with {:ok, %{"access_token" => access_token} = new_state} <- get_access_token(),
         {:ok, value} <- get_secret_call(name, access_token) do
      {:ok, value, state |> Map.merge(new_state) |> Map.put("issued_at", get_current_epoch())}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret_call(name, access_token) do
    client = http_adpater()
    key_vault_name = Config.provider_config_value(:azure_managed_identity, :key_vault_name)

    with {:ok, %{body: body, status_code: 200}} <-
           client.get(
             "https://#{key_vault_name}.vault.azure.net/secrets/#{name}?api-version=2016-10-01",
             %{"Authorization" => "Bearer #{access_token}"}
           ),
         {:ok, %{"value" => value}} <- Poison.decode(body) do
      {:ok, value}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_access_token() do
    client = http_adpater()

    with {:ok, %{body: body, status_code: 200}} <-
           token_uri()
           |> client.get(@headers),
         {:ok, data} <- Poison.decode(body) do
      {:ok, data}
    else
      _ ->
        {:error, "Failed to get access token"}
    end
  end

  defp get_current_epoch() do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  defp http_adpater() do
    Application.get_env(:ex_secrets, :http_adapter, HTTPoison)
  end

  def process_name() do
    :ex_secrets_azure_managed_identity
  end
end
