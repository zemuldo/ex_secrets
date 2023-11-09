defmodule ExSecrets do
  @moduledoc """
  This module functions to access secrets in an Elixir application.
  """

  alias ExSecrets.Cache
  alias ExSecrets.Utils.Resolver
  alias ExSecrets.Utils.SecretFetchLimiter

  require Logger

  @doc """
  Get secret value.
  You can pass two options:
    - provider: Name of the provider to use. Default is :system_env
    - default_value: Default value to return if secret is not found. Default is nil

  ## Examples

      iex> ExSecrets.get("FOO")
      nil
      iex> Application.put_env(:ex_secrets, :default_provider, :dot_env)
      :ok
      iex> ExSecrets.get("FOO")
      nil
      iex> System.put_env "FOO", "BAR"
      :ok
      iex> ExSecrets.get("FOO")
      "BAR"
      iex> System.delete_env "FOO"
      :ok
      iex> ExSecrets.get("FOO")
      "BAR"
      iex> ExSecrets.reset()
      :ok
      iex> ExSecrets.get("FOO")
      nil
      iex> Application.delete_env(:ex_secrets, :default_provider)
      :ok
      iex> Application.put_env(:ex_secrets, :providers, %{dot_env: %{path: "test/support/fixtures/dot_env_test.env"}})
      :ok
      iex> ExSecrets.get("ERL", provider: :dot_env)
      nil
      iex> ExSecrets.get("ERL", provider: :dot_env, default_value: "ANG")
      "ANG"
      iex> Application.delete_env(:ex_secrets, :providers)
      :ok
      iex> Application.put_env(:ex_secrets, :providers, %{dot_env: %{path: "test/support/fixtures/dot_env_test.env"}})
      :ok
      iex> ExSecrets.get("DEVS", provider: :dot_env)
      "ROCKS"
      iex> Application.delete_env(:ex_secrets, :providers)
      :ok
  """
  @spec get(String.t(), provider: atom(), default_value: any()) :: String.t() | nil
  def get(key, opts \\ [])

  def get(key, []) do
    with provider when is_atom(provider) <- get_any_provider(),
         value when not is_nil(value) <- get(key, provider: provider) do
      value
    else
      _ -> get_default(key)
    end
  end

  def get(key, provider: provider, default_value: default_value) do
    with value when is_nil(value) <- Cache.get(key),
         fetch <- SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider]),
         value when not is_nil(value) <- Cache.pass_by(key, fetch) do
      value
    else
      nil -> default_value
      value -> value
    end
  end

  def get(key, provider: provider) do
    with value when is_nil(value) <- Cache.get(key),
         fetch <- SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider]),
         value when not is_nil(value) <- Cache.pass_by(key, fetch) do
      value
    else
      nil -> get_default(key)
      value -> value
    end
  end

  def get(key, default_value: default_value) do
    with value when is_nil(value) <- Cache.get(key),
         provider <- get_any_provider(),
         fetch <- SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider]),
         value when not is_nil(value) <- Cache.pass_by(key, fetch) do
      value
    else
      nil -> default_value
      value -> value
    end
  end

  def get(key, provider) do
    m = "ExSecrets.get(key, provider) is deprecated. Use ExSecrets.get/2 with options."

    IO.puts("#{IO.ANSI.yellow()}ExSecrets Warning ==> #{NaiveDateTime.utc_now()} ==> #{m}")

    get(key, provider: provider)
  end

  @doc """
  Get secret value with provider name and default value
  """
  @deprecated "Use get/2 instead."
  def get(key, provider, default) do
    case get(key, provider: provider) do
      nil -> default
      value -> value
    end
  end

  @doc """
  Set secret value.

  Supported for providers:

  - :system_env
  - :dot_env
  - :azure_key_vault
  - :azure_managed_identity
  - :google_secret_manager

  Calling this function requires the provider to be configured with credentials that allow create secrets like Secret Admionistrator in Azure Key Vault.

  ## Examples

      iex> File.touch(".env.dev")
      :ok
      iex> Application.put_env(:ex_secrets, :providers, %{dot_env: %{path: ".env.dev"}})
      :ok
      iex> ExSecrets.set("TEST", "test", provider: :dot_env)
      :ok
      iex> Application.delete_env(:ex_secrets, :providers)
      :ok
      iex> File.rm(".env.dev")
  """

  @spec set(String.t(), String.t(), Keyword.t()) :: :ok | :error
  def set(key, value, opts \\ [])

  def set(key, value, opts) do
    with provider <- Keyword.get(opts, :provider),
         provider when is_atom(provider) <- Resolver.call(provider),
         :ok <- Kernel.apply(provider, :set, [key, value]) do
      Cache.save(key, value)
      :ok
    else
      _ ->
        :error
    end
  end

  @doc """
  Internal function for fetching secret with provide for catching and rate limiting.
  Do not rely on this function.
  """
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
         provider when provider not in [:system_env] <- get_default_prider(),
         fetch <- SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider]) do
      Cache.pass_by(key, fetch)
    else
      provider when is_atom(provider) -> get_using_provider(key, provider)
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

  @doc """
  Resets cache and reloads all providers.
  """
  def reset() do
    GenServer.call(:ex_secrets_cache_store, :clear)
    ExSecrets.Application.get_providers() |> Enum.each(&Kernel.apply(&1, :reset, []))
    :ok
  end
end
