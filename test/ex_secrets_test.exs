defmodule ExSecretsTest do
  use ExUnit.Case
  doctest ExSecrets

  test "Get FOO - nil" do
    k = "FOO#{:rand.uniform(100)}"
    assert ExSecrets.get(k) == nil
  end

  test "Get FOO - BAR" do
    k = "FOO#{:rand.uniform(100)}"
    System.put_env(k, "BAR")
    assert ExSecrets.get(k) == "BAR"
    System.delete_env(k)
  end

  test "Get with Provider FOO - BAR" do
    k = "FOO#{:rand.uniform(100)}"
    System.put_env(k, "BARR")
    assert ExSecrets.get(k, :system_env) == "BARR"
    System.delete_env(k)
  end

  test "Get with wring Provider FOOOZ - BARRZ" do
    k = "FOO#{:rand.uniform(100)}"
    System.put_env(k, "BARRZ")
    assert ExSecrets.get(k, :abc) == nil
    System.delete_env(k)
  end

  test "Get with configuration FOO - BAR" do
    k = "FOO#{:rand.uniform(100)}"
    Application.put_env(:ex_secrets, :providers, [:xyz])
    System.put_env(k, "BARR")
    assert ExSecrets.get(k, :system_env) == "BARR"
    System.delete_env(k)
  end
end
