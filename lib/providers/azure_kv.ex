defmodule ExSecrets.Providers.AzureKeyVault do
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end
end
