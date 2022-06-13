defmodule ExSecrets.Providers.Mix do
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end

  def process_name() do
    :ex_secrets_mix
  end
end
