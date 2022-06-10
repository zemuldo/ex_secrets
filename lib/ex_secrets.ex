defmodule ExSecrets do
  def get(name) do
    ExSecrets.Providers.SystemEnv.get(name)
  end
end
