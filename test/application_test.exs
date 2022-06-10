defmodule ExSecrets.ApplicationTestsInvalidConfig do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :providers, :wrong)
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
    Application.put_env(:ex_secrets, :providers, [:xyz])
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
    Application.put_env(:ex_secrets, :providers, [:system_env])
  end

  test "test" do
    assert_raise ExSecrets.Exceptions.UnknowProvider, fn ->
      ExSecrets.Application.get_providers()
    end
  end
end

defmodule ExSecrets.ApplicationTestsUserProvider do
  use ExUnit.Case

  setup do
    Application.put_env(:ex_secrets, :providers, [:dot_env])
  end

  test "test" do
    assert ExSecrets.Providers.DotEnv in ExSecrets.Application.get_providers()
  end
end
