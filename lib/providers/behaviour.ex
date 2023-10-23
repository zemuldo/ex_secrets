defmodule ExSecrets.Providers.Behaviour do
  @moduledoc """
  Behaviour for providers.
  """

  @doc """
  Resets the provider to default state. Clears cache and resets the provider.
  """
  @callback reset() :: :ok

  @doc """
  Gets a secret from the provider.
  """
  @callback get(String.t()) :: String.t()
end
