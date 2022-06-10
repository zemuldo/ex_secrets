defmodule ExSecrets.Application do
  use Application

  @default_providers [
    :system_env
  ]

  def start(_type, _args) do
    children = [{ExSecrets.Cache.Store, []} | get_providers()]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def get_providers() do
    get_providers_env()
    |> Enum.map(&get_provider/1)
  end

  def get_providers(_), do: []

  defp get_provider(p) do
    with true <- is_atom(p),
         false <- p in @default_providers,
         module when is_atom(module) <- ExSecrets.Providers.Resolver.call(p) do
          module
    else
      _ ->
        raise(ExSecrets.Exceptions.UnknowProvider, "Unknown provider: #{p}")
    end
  end

  defp get_providers_env() do
    case Application.get_env(:ex_secrets, :providers, []) do
      providers when is_list(providers) -> providers
      nil -> []
      _ -> raise(ExSecrets.Exceptions.InvalidConfiguration, "Unknown provider: ")
    end
  end
end
