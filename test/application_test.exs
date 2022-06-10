defmodule ExSecrets.ApplicationTestsInvalidConfig do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :provider, "wrong")
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
    Application.put_env(:ex_secrets, :provider, [:xyz])
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
    Application.put_env(:ex_secrets, :provider, [:system_env])
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
    Application.put_env(:ex_secrets, :provider, :dot_env)
  end

  test "test" do
    assert ExSecrets.Providers.DotEnv in ExSecrets.Application.get_providers()
  end
end

defmodule ExSecrets.ApplicationTestsUserManyProviders do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :provider, [:dot_env])
  end

  test "test" do
    assert ExSecrets.Providers.DotEnv in ExSecrets.Application.get_providers()
  end
end
