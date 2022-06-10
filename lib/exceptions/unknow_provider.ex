defmodule ExSecrets.Exceptions.UnknowProvider do
  defexception [:message]

  def exception(msg) do
    %__MODULE__{message: msg}
  end
end
