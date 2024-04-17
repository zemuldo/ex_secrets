defmodule ExSecrets.Providers.AwsSecretsManager do
  use ExSecrets.Providers.Base

  @moduledoc """
  This module functions to access secrets in an Elixir application.
  """

  @process_name :ex_secrets_aws_secrets_manager

  def reset() do
    :ok
  end

  def init(_) do
    {:ok, %{}}
  end

  def set(_, _) do
    {:error, "set is not supported for AWS Secrets Manager"}
  end

  def get(name) do
    name = name |> String.split("_") |> Enum.join("-")

    with process when not is_nil(process) <-
           GenServer.whereis(@process_name) do
      GenServer.call(@process_name, {:get, name})
    else
      nil ->
        case get_secret(name, %{}, get_current_epoch()) do
          {:ok, value, _} -> value
          _ -> nil
        end
    end
  end

  def get_secret(name, %{}, _) do
    with {:ok, secret} <- Utils.AwsRequest.call(name),
         value <- get_value(secret) do
      {:ok, value, %{}}
    else
      _err ->
        nil
    end
  end

  def handle_call({:get, name}, _from, state) do
    case get_secret(name, state, get_current_epoch()) do
      {:ok, secret, state} -> {:reply, secret, state}
      _ -> {:reply, nil, state}
    end
  end

  defp get_current_epoch() do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  def process_name() do
    @process_name
  end

  defp get_value("{" <> _ = value) do
    with {:ok, data} <- Jason.decode(value),
         [key] <- Map.keys(data) do
      data[key]
    else
      _err ->
        value
    end
  end

  defp get_value(value), do: value
end
