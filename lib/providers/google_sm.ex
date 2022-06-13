defmodule ExSecrets.Providers.GoogleSecretManager do
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end

  def process_name() do
    :ex_secrets_google_secret_manager
  end
end
