defmodule ExSecrets.ApplicationTestsInvalidConfig do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :providers, "wrong")
    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
  end

  test "test" do
    assert_raise ExSecrets.Exceptions.InvalidConfiguration, fn ->
      ExSecrets.Application.get_providers()
    end
  end
end

defmodule ExSecrets.ApplicationTestsUnknowProvider do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :providers, %{xyz: %{path: "xyz"}})
    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
  end

  test "test" do
    assert_raise ExSecrets.Exceptions.UnknowProvider, fn ->
      ExSecrets.Application.get_providers()
    end
  end
end

defmodule ExSecrets.ApplicationTestsDefaultProvider do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :providers, %{system_env: %{path: "system_env"}})
    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
  end

  test "test" do
    assert_raise ExSecrets.Exceptions.UnknowProvider, fn ->
      ExSecrets.Application.get_providers()
    end
  end
end

defmodule ExSecrets.ApplicationTestsUserSingleProvider do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :providers, %{
      dot_env: %{path: "test/support/fixtures/dot_env_test.env"}
    })

    on_exit(fn -> Application.delete_env(:ex_secrets, :providers) end)
  end

  test "test" do
    assert ExSecrets.Providers.DotEnv in ExSecrets.Application.get_providers()
  end
end

defmodule ExSecrets.ApplicationTestsUserManyProviders do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :providers, %{dot_env: %{}})
  end

  test "test" do
    assert ExSecrets.Providers.DotEnv in ExSecrets.Application.get_providers()
  end
end
