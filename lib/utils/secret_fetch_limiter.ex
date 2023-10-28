defmodule ExSecrets.Utils.SecretFetchLimiter do
  @moduledoc """
  Secret fetch limiter module limits the number of secret fetches in a given time.
  """
  require Logger
  use GenServer

  @table_name :ex_secrets_fetch_limiter_table
  @process_name :ex_secrets_fetch_limiter

  @secret_fetch_limit_timer :timer.seconds(60)
  @secret_fetch_limit 5
  @on_secret_fetch_limit_reached :ignore

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  @impl true
  def init(_) do
    table = :ets.new(@table_name, [:named_table, :public, :bag, read_concurrency: true])
    :timer.send_interval(:timer.seconds(5), :clear)
    {:ok, %{table: table}}
  end

  @impl true
  def handle_info(:clear, state) do
    # https://elixirforum.com/t/how-to-delete-ets-records-older-than-xxx/43954
    now = current_time()
    :ets.select_delete(@table_name, [{{:"$1", :"$2"}, [{:<, :"$2", now}], [true]}])
    {:noreply, state}
  end

  def allow(key, module, function, args) do
    case {:ets.whereis(@table_name), args} do
      {_, [_, :system_env]} ->
        Kernel.apply(module, function, args)

      {:undefined, _} ->
        Kernel.apply(module, function, args)

      {_, _} ->
        now = current_time()

        @table_name
        |> :ets.select([{{key, :"$1"}, [{:>, :"$1", now}], [:"$1"]}])
        |> Enum.count()
        |> Kernel.<=(
          Application.get_env(
            :ex_secrets,
            :secret_fetch_limit,
            @secret_fetch_limit
          )
        )
        |> case do
          true ->
            track(key)
            Kernel.apply(module, function, args)

          false ->
            limit_reached(key, [module, function, args])
        end
    end
  end

  def track(key) do
    expires_in =
      :ets.lookup(@table_name, key)
      |> Enum.count()
      |> Kernel.+(1)
      |> Kernel.*(5)
      |> Kernel.+(
        Application.get_env(:ex_secrets, :secret_fetch_limit_timer, @secret_fetch_limit_timer)
      )
      |> :timer.seconds()

    :ets.insert(@table_name, {key, current_time() + expires_in})
  end

  defp current_time() do
    System.system_time(:millisecond)
  end

  defp limit_reached(key, [module, function, args]) do
    limit =
      Application.get_env(
        :ex_secrets,
        :secret_fetch_limit,
        @secret_fetch_limit
      )

    case Application.get_env(
           :ex_secrets,
           :on_secret_fetch_limit_reached,
           @on_secret_fetch_limit_reached
         ) do
      :ignore ->
        Kernel.apply(module, function, args)

      :warn ->
        Logger.warn("Fetch secret #{key} reached limit #{limit}")
        Kernel.apply(module, function, args)

      :raise ->
        raise "Fetch secret #{key} reached limit #{limit}"

      _ ->
        Logger.error("Fetch secret #{key} reached limit #{limit}")
        Kernel.apply(module, function, args)
    end
  end
end
