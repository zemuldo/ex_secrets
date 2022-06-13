defmodule ExSecrets.HTTPAdapterBehavior do
  @callback get(binary(), map()) :: {:ok, map()} | {:error, binary()}
  @callback post(binary(), map(), map()) :: {:ok, map()} | {:error, binary()}
end
