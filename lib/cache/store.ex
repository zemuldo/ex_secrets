defmodule ExSecrets.Cache.Store do
  use GenServer

  @store_name :ex_secrets_cache_store

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, [], name: @store_name)
  end

  @impl true
  def init(_) do
    table = :ets.new(:ex_secrets_ets_table, [:set, read_concurrency: true])
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:get, key}, _from, %{table: table} = state) do
    case :ets.lookup(table, key) do
      [{_, value}] -> {:reply, value, state}
      _ -> {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:save, key, value}, _from, %{table: table} = state) do
    true = :ets.insert(table, {key, value})
    {:reply, value, state}
  end

  def get(key) do
    case GenServer.whereis(@store_name) do
      nil -> nil
      _ -> GenServer.call(@store_name, {:get, key})
    end
  end

  @spec save(any, any) :: any
  def save(key, value) do
    case GenServer.whereis(@store_name) do
      nil ->
        value

      _ ->
        GenServer.call(@store_name, {:save, key, value})
    end
  end
end
