defmodule ExSecrets.Providers.AwsSecretsManager do
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end

  def process_name() do
    :ex_secrets_aws_secrets_manager
  end
end
