defmodule ExSecrets.Providers.AzureManagedIdentity do
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end
end
