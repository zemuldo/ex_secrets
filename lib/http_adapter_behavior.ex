defmodule ExSecrets.HTTPAdapterBehavior do
  @moduledoc """
  Behaviour for HTTP adapters.
  """
  @callback get(binary(), map()) :: {:ok, map()} | {:error, binary()}
  @callback post(binary(), map(), map()) :: {:ok, map()} | {:error, binary()}
end
