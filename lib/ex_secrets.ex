defmodule ExSecrets do
  alias ExSecrets.Cache
  alias ExSecrets.Providers.{Resolver, SystemEnv}

  def get(key) do
    with value when not is_nil(value) <- Cache.get(key) do
      value
    else
      nil ->
        Cache.pass_by(key, SystemEnv.get(key))
    end
  end

  def get(key, provider) do
    with value when not is_nil(value) <- Cache.get(key) do
      value
    else
      nil ->
        Cache.pass_by(key, get_using_provider(key, provider))
    end
  end

  defp get_using_provider(key, provider) do
    with provider when is_atom(provider) <- Resolver.call(provider),
         value <- Kernel.apply(provider, :get, [key]) do
      value
    else
      _ -> nil
    end
  end
end
