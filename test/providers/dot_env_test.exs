defmodule ExSecrets.Providers.DotEnvTest do
  use ExUnit.Case
  doctest ExSecrets

  test "Get with startup" do
    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test.env"}
    })

    {:ok, _} = GenServer.start(ExSecrets.Providers.DotEnv, [])
    assert ExSecrets.get("JAVA", :dot_env) == "SCRIPT"
  end

  test "Get without startup" do
    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test_2.env"}
    })

    assert ExSecrets.get("ASD", :dot_env) == "FGH"
  end

  test "reset" do
    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test.env"}
    })

    {:ok, _} = GenServer.start(ExSecrets.Providers.DotEnv, [])
    assert ExSecrets.get("JAVA", :dot_env) == "SCRIPT"

    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test_3.env"}
    })

    ExSecrets.Providers.DotEnv.reset()

    assert ExSecrets.get("JAVA", :dot_env) == "SCRIPTT"

    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test.env"}
    })
  end
end
