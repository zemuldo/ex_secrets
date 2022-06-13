defmodule ExSecrets.Providers.DotEnvTest do
  use ExUnit.Case
  doctest ExSecrets

  setup do
    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test.env"}
    })

    {:ok, _} = GenServer.start(ExSecrets.Providers.DotEnv, [])
    {:ok, %{}}
  end

  test "Get FOO - nil" do
    assert ExSecrets.get("JAVA", :dot_env) == "SCRIPT"
  end
end
