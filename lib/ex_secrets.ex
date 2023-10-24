defmodule ExSecrets do
  @moduledoc """
  This module functions to access secrets in an Elixir application.

  Configuration is available for all secret providers:

  Provider specific configurations.
  """

  alias ExSecrets.Cache
  alias ExSecrets.Utils.Resolver
  alias ExSecrets.Utils.SecretFetchLimiter

  @doc """
  Get secret value

  ## Examples

      iex(1)> ExSecrets.get("FOO")
      nil
      iex(2)> Application.put_env(:ex_secrets, :default_provider, :dot_env)
      :ok
      iex(3)> ExSecrets.get("FOO")
      nil
      iex(4)> System.put_env "FOO", "BAR"
      :ok
      iex(5)> ExSecrets.get("FOO")
      "BAR"
      iex(6)> System.delete_env "FOO"
      :ok
      iex(7)> Application.delete_env(:ex_secrets, :default_provider)
      :ok
  """
  def get(key) do
    case get_any_provider() do
      provider when is_atom(provider) -> get(key, provider)
      _ -> get_default(key)
    end
  end

  @doc """
  Get secret value with provider name.

  ## Examples
      iex(1)> Application.put_env(:ex_secrets, :providers, %{dot_env: %{path: "test/support/fixtures/dot_env_test.env"}})
      :ok
      iex(2)> ExSecrets.get("JAVA", :dot_env)
      "SCRIPT"
      iex(3)> ExSecrets.get("JAVA")
      "SCRIPT"
      iex(4)> Application.delete_env(:ex_secrets, :providers)
      :ok
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

  ## Examples
      iex(1)> Application.put_env(:ex_secrets, :providers, %{dot_env: %{path: "test/support/fixtures/dot_env_test.env"}})
      :ok
      iex(2)> ExSecrets.get("ERL", :dot_env)
      nil
      iex(3)> ExSecrets.get("ERL", :dot_env, "ANG")
      "ANG"
      iex(4)> Application.delete_env(:ex_secrets, :providers)
      :ok
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
      _ -> get_default(key)
    end
  end

  defp get_default(key) do
    with value when is_nil(value) <- Cache.get(key),
         provider <- get_default_prider() do
      Cache.pass_by(
        key,
        SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider])
      )
    else
      value -> value
    end
  end

  defp get_default_prider() do
    Application.get_env(:ex_secrets, :default_provider, :system_env)
  end

  defp get_any_provider() do
    with providers when is_map(providers) <-
           Application.get_env(:ex_secrets, :providers, %{}),
         provider <- Map.keys(providers) |> Kernel.++([:system_env]) |> Enum.at(0) do
      provider
    else
      _ -> nil
    end
  end

  def clear_cache(), do: GenServer.call(Cache, :clear)

  def reset() do
    n = GenServer.call(:ex_secrets_cache_store, :clear)
    ExSecrets.Application.get_providers() |> Enum.each(&Kernel.apply(&1, :reset, []))
    {:ok, n}
  end
end
