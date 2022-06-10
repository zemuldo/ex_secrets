defmodule ExSecrets.Providers.SystemEnv do
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end

  def get(name) do
    System.get_env(name)
  end
end
