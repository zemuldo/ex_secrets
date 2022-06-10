defmodule ExSecrets.Providers.Base do
  defmacro __using__(_) do
    quote do
      use GenServer

      def start_link(default) when is_list(default) do
        GenServer.start_link(get_name(default), default)
      end

      defp get_name(opts) do
        opts[:name] || __MODULE__
      end
    end
  end
end
