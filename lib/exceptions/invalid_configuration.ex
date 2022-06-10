defmodule ExSecrets.Exceptions.InvalidConfiguration do
  defexception [:message]

  def exception(msg) do
    %__MODULE__{message: msg}
  end
end
