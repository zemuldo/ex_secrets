defmodule ExSecrets.Providers.Mix do
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end

  def get(key) do
    Application.get_env(:ex_secrets, key, nil)
  end

  def process_name() do
    :ex_secrets_mix
  end
end
