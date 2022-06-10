defmodule ExSecrets.Providers.DotEnvTest do
  use ExUnit.Case
  doctest ExSecrets

  setup do
    {:ok, _} = GenServer.start(ExSecrets.Providers.DotEnv, [])
    {:ok, %{}}
  end

  test "Get FOO - nil" do
    assert ExSecrets.get("JAVA", :dot_env) == "SCRIPT"
  end
end
