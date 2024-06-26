defmodule ExSecrets.Utils.Resolver do
  @moduledoc """
  Resolver module resolves the provider name to the actual provider module.
  """
  def call(:system_env), do: ExSecrets.Providers.SystemEnv
  def call(:dot_env), do: ExSecrets.Providers.DotEnv
  def call(:azure_managed_identity), do: ExSecrets.Providers.AzureManagedIdentity
  def call(:azure_key_vault), do: ExSecrets.Providers.AzureKeyVault
  def call(:google_secret_manager), do: ExSecrets.Providers.GoogleSecretManager
  def call(:aws_secrets_manager), do: ExSecrets.Providers.AwsSecretsManager
  def call(_), do: {:error, "Unknown secret provider"}
end
