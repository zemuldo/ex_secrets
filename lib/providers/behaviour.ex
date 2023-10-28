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

  @callback set(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
end
