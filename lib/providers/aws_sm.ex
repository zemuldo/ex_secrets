defmodule ExSecrets.Providers.AwsSecretsManager do
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end
end
