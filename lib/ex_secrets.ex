defmodule ExSecrets do
  alias ExSecrets.Cache
  alias ExSecrets.Providers.Resolver

  def get(key) do
    with value <- ExSecrets.Providers.SystemEnv.get(key),
         value <- Cache.pass_by(key, value) do
      value
    else
      _ -> nil
    end
  end

  def get(key, provider) do
    with provider when is_atom(provider) <- Resolver.call(provider),
         value <- Kernel.apply(provider, :get, [key]),
         value <- Cache.pass_by(key, value) do
      value
    else
      _ -> nil
    end
  end
end
