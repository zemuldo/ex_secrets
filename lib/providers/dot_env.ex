defmodule ExSecrets.Providers.DotEnv do
  use ExSecrets.Providers.Base
  alias ExSecrets.Cache

  def get(key), do: Cache.get(key)

  def init(_) do
    read_env()
    {:ok, %{}}
  end

  defp read_env() do
    with {:ok, s} <- File.read(".env"),
         [_ | _] = envs <- String.split(s,  ~r{(\r\n|\r|\n|\\n)}, trim: true) do
      Enum.each(envs, &put_env/1)
    else
      _ -> raise(raise(ExSecrets.Exceptions.InvalidConfiguration, ".env is not found"))
    end
  end

  defp put_env(s) do
    [k | rest] = String.split(s, "=", trim: true)

    v = Enum.join(rest, "=")

    Cache.save(k, v)
  end
end
