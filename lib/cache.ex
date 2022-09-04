defmodule ExSecrets.Cache do
  use GenServer

  @store_name :ex_secrets_cache_store

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, [], name: @store_name)
  end

  @impl true
  def init(_) do
    table = :ets.new(:ex_secrets_ets_table, [:set, read_concurrency: true])
    {:ok, %{table: table, master_key: :crypto.strong_rand_bytes(16)}}
  end

  @impl true
  def handle_call({:get, key}, _from, %{table: table, master_key: master_key} = state) do
    case :ets.lookup(table, key) do
      [{_, value}] -> {:reply, decrypt(value, master_key), state}
      _ -> {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:save, key, value}, _from, %{table: table, master_key: master_key} = state) do
    encrypted_value = encrypt(value, master_key)
    true = :ets.insert(table, {key, encrypted_value})
    {:reply, value, state}
  end

  def get(key) do
    case System.get_env(key) do
      value when is_binary(value) -> value
      nil ->
        case GenServer.whereis(@store_name) do
          nil -> System.get_env(key)
          _ -> GenServer.call(@store_name, {:get, key})
        end
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

  def pass_by(_, nil), do: nil
  def pass_by(nil, value), do: value

  def pass_by(key, value) do
    case get(key) do
      nil -> save(key, value)
      value -> value
    end
  end

  defp encrypt(plaintext, key) do
    iv = :crypto.strong_rand_bytes(16)
    ciphertext = :crypto.crypto_one_time(:aes_128_ctr, key, iv, plaintext, true)
    iv <> ciphertext
  end

  defp decrypt(ciphertext, key) do
    <<iv::binary-16, ciphertext::binary>> = ciphertext

    :crypto.crypto_one_time(:aes_128_ctr, key, iv, ciphertext, false)
  end
end
