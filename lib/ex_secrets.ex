defmodule ExSecrets do
  @moduledoc """
  This module functions to access secrets in an Elixir application.

  Configuration is available for all secret providers:

  Provider specific configurations.

  Azure KeyVault configuration:
      config :ex_secrets, :providers, %{
        azure_key_vault: %{
          tenant_id: "tenant-id",
          client_id: "client-id",
          client_secret: "client-secret",
          key_vault_name: "key-vault-name"
        }

  Azure Managed Identity Configuration:
      config :ex_secrets, :providers, %{
        azure_managed_identity: %{
          key_vault_name: "KKEYvault-name"
        }

  Dotenv file:
      config :ex_secrets, :providers, %{
        dot_env: %{path: "/path/.env"}
      })

  """

  alias ExSecrets.Cache
  alias ExSecrets.Providers.SystemEnv
  alias ExSecrets.Utils.Resolver
  alias ExSecrets.Utils.SecretFetchLimiter

  @doc """
  Get secret value
  """
  def get(key) do
    case get_default_prider() do
      provider when is_atom(provider) -> get(key, provider)
      _ -> get_default(key)
    end
  end

  @doc """
  Get secret value with provider name
  """
  def get(key, provider) do
    with value when not is_nil(value) <- Cache.get(key) do
      value
    else
      nil ->
        Cache.pass_by(
          key,
          SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider])
        )
    end
  end

  @doc """
  Get secret value with provider name and default value
  """
  def get(key, provider, default) do
    with value when not is_nil(value) <- Cache.get(key) do
      value
    else
      nil ->
        case Cache.pass_by(
               key,
               SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider])
             ) do
          nil -> default
          value -> value
        end
    end
  end

  def get_using_provider(key, provider) do
    with provider when is_atom(provider) <- Resolver.call(provider),
         value <- Kernel.apply(provider, :get, [key]) do
      value
    else
      _ -> nil
    end
  end

  defp get_default(key) do
    with value when not is_nil(value) <- Cache.get(key) do
      value
    else
      nil ->
        Cache.pass_by(key, SystemEnv.get(key))
    end
  end

  defp get_default_prider() do
    Application.get_env(:ex_secrets, :default_provider, get_any_provider())
  end

  defp get_any_provider() do
    with providers when is_map(providers) <-
           Application.get_env(:ex_secrets, :providers, %{}),
         provider <- Map.keys(providers) |> Kernel.++([:system_env]) |> Enum.at(0) do
      provider
    else
      _ -> raise(ExSecrets.Exceptions.InvalidConfiguration)
    end
  end

  def clear_cache(), do: GenServer.cast(Cache, :clear)

  def reset() do
    providers = ExSecrets.Application.get_providers()

    Enum.each(providers, fn provider ->
      case Resolver.call(provider) do
        {:error, _} -> :ok
        provider -> Kernel.apply(provider, :reset, [])
      end
    end)
  end
end
