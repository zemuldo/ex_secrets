defmodule ExSecrets do
  alias ExSecrets.Cache
  alias ExSecrets.Providers.SystemEnv
  alias ExSecrets.Utils.Resolver
  alias ExSecrets.Utils.SecretFetchLimiter

  def get(key) do
    case get_default_prider() do
      provider when is_atom(provider) -> get(key, provider)
      _ -> get_default(key)
    end
  end

  def get(key, provider) do
    with value when not is_nil(value) <- Cache.get(key) do
      value
    else
      nil ->
        Cache.pass_by(key, SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider]))
    end
  end

  def get(key, provider, default) do
    with value when not is_nil(value) <- Cache.get(key) do
      value
    else
      nil ->
        case Cache.pass_by(key, SecretFetchLimiter.allow(key, ExSecrets, :get_using_provider, [key, provider])) do
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

  def get_default(key) do
    with value when not is_nil(value) <- Cache.get(key) do
      value
    else
      nil ->
        Cache.pass_by(key, SystemEnv.get(key))
    end
  end

  def get_default_prider() do
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
end
