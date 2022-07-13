defmodule ExSecrets.Utils.Resolver do
  def call(:system_env), do: ExSecrets.Providers.SystemEnv
  def call(:dot_env), do: ExSecrets.Providers.DotEnv
  def call(:azure_managed_identity), do: ExSecrets.Providers.AzureManagedIdentity
  def call(:azure_key_vault), do: ExSecrets.Providers.AzureKeyVault
  def call(_), do: {:error, "Unknown secret provider"}
end
