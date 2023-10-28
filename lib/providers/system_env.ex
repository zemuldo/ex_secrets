defmodule ExSecrets.Providers.SystemEnv do
  @moduledoc """
  SystemEnv provider provides secrets from the system environment.
  """
  use ExSecrets.Providers.Base

  def init(_) do
    {:ok, %{}}
  end

  def reset() do
    :ok
  end

  def get(name) do
    System.get_env(name)
  end

  def set(name, value) do
    System.put_env(name, value)
    {:ok, value}
  end

  def process_name() do
    :ex_secrets_system_env
  end
end
