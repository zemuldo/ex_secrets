defmodule ExSecrets.Providers.Behaviour do
  @callback reset() :: :ok
  @callback get(String.t()) :: String.t()
end
