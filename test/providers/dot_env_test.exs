defmodule ExSecrets.Providers.DotEnvTest do
  use ExUnit.Case

  test "Get with startup" do
    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test.env"}
    })

    {:ok, _} = GenServer.start(ExSecrets.Providers.DotEnv, [])
    assert ExSecrets.get("JAVA", provider: :dot_env) == "SCRIPT"
    Application.delete_env(:ex_secrets, :providers)
  end

  test "Get without startup" do
    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test_2.env"}
    })

    assert ExSecrets.get("ASD", provider: :dot_env) == "FGH"
    Application.delete_env(:ex_secrets, :providers)
  end

  test "reset" do
    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test.env"}
    })

    {:ok, _} = GenServer.start(ExSecrets.Providers.DotEnv, [])
    assert ExSecrets.get("JAVA", provider: :dot_env) == "SCRIPT"

    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test_3.env"}
    })

    ExSecrets.Providers.DotEnv.reset()

    assert ExSecrets.get("JAVA", provider: :dot_env) == "SCRIPTT"

    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test.env"}
    })

    Application.delete_env(:ex_secrets, :providers)
  end
end
