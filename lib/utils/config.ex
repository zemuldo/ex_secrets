defmodule ExSecrets.Utils.Config do
  @moduledoc """
  Config module provides helper functions for getting configuration values.
  """
  def provider_config_value(provider, key) do
    provider
    |> provider_env()
    |> Map.get(key)
  end

  def provider_env(provider) do
    with env when is_map(env) <-
           Application.get_env(:ex_secrets, :providers, %{})
           |> Map.get(provider) do
      env
    else
      _ -> %{}
    end
  end
end
