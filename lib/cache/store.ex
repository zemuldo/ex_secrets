defmodule ExSecrets.Cache.Store do
  use Agent

  @store_name :ex_secrets_cache_store

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: @store_name)
  end

  def get(key) do
    case GenServer.whereis(@store_name) do
      nil -> nil
      _ -> Agent.get(@store_name, &Map.get(&1, key))
    end
  end

  def save(key, value) do
    case GenServer.whereis(@store_name) do
      nil ->
        value

      _ ->
        :ok = Agent.update(@store_name, &Map.put(&1, key, value))
        value
    end
  end
end
