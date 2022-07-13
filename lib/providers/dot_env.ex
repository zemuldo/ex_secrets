defmodule ExSecrets.Providers.DotEnv do
  use ExSecrets.Providers.Base
  alias ExSecrets.Cache
  alias ExSecrets.Utils.Config

  def get(key) do
    case GenServer.whereis(process_name()) do
      pid when is_pid(pid) ->
        Cache.get(key)

      _ ->
        get_scripted(key)
    end
  end

  def init(_) do
    read_env()
    {:ok, %{}}
  end

  defp read_env() do
    path = Config.provider_config_value(:dot_env, :path)

    with {:ok, s} <- File.read(path),
         [_ | _] = envs <- String.split(s, ~r{(\r\n|\r|\n|\\n)}, trim: true) do
      Enum.each(envs, &put_env/1)
    else
      _ -> raise(raise(ExSecrets.Exceptions.InvalidConfiguration, ".env is not found"))
    end
  end

  defp get_scripted(key) do
    path = Config.provider_config_value(:dot_env, :path)

    with {:ok, s} <- File.read(path),
         [_ | _] = envs <- String.split(s, ~r{(\r\n|\r|\n|\\n)}, trim: true) do
      Enum.find(envs, &(get_k_v(&1) |> is_value(key))) |> get_v()
    else
      _ -> raise(raise(ExSecrets.Exceptions.InvalidConfiguration, ".env is not found"))
    end
  end

  defp put_env(s) do
    {k, v} = get_k_v(s)

    Cache.save(k, v)
  end

  defp get_v(s) do
    case get_k_v(s) do
      {_k, v} -> v
      _ -> nil
    end
  end

  defp get_k_v(s) do
    [k | rest] = String.split(s, "=", trim: true)

    v = Enum.join(rest, "=")

    {k, v}
  end

  defp is_value({k, _v}, key), do: k == key
  defp is_value(_, _), do: false

  def process_name() do
    :ex_secrets_dot_env
  end
end
