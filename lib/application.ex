defmodule ExSecrets.Application do
  use Application

  alias ExSecrets.Providers.SystemEnv
  alias ExSecrets.Utils.Resolver
  alias ExSecrets.Utils.SecretFetchLimiter
  alias ExSecrets.Cache

  @default_providers [
    SystemEnv
  ]

  def start(_type, _args) do
    children = [{Cache, []}, SecretFetchLimiter | get_providers()] ++ @default_providers

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def get_providers() do
    get_providers_env()
    |> Enum.map(&get_provider/1)
  end

  def get_providers(_), do: []

  defp get_provider(p) do
    with true <- is_atom(p),
         module when is_atom(module) <- Resolver.call(p),
         false <- module in @default_providers do
      module
    else
      _ ->
        raise(ExSecrets.Exceptions.UnknowProvider, "Unknown provider: #{p}")
    end
  end

  defp get_providers_env() do
    case Application.get_env(:ex_secrets, :providers, %{}) do
      providers when is_map(providers) -> providers |> Map.keys()
      _ -> raise(ExSecrets.Exceptions.InvalidConfiguration)
    end
  end
end
