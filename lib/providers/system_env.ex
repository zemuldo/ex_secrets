defmodule ExSecrets.Providers.SystemEnv do
  def get(name) do
    System.get_env(name)
  end
end
