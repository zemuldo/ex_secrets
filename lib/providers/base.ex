defmodule ExSecrets.Providers.Base do
  defmacro __using__(_) do
    quote do
      use GenServer

      @behaviour ExSecrets.Providers.Behaviour

      def start_link(default) when is_list(default) do
        GenServer.start_link(__MODULE__, [], name: get_name(default))
      end

      defp get_name(opts) do
        __MODULE__.process_name()
      end
    end
  end
end
