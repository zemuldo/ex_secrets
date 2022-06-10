defmodule ExSecretsTest do
  use ExUnit.Case
  doctest ExSecrets

  test "Get FOO - nil" do
    assert ExSecrets.get("FOO") == nil
  end

  test "Get FOO - BAR" do
    System.put_env("FOO", "BAR")
    assert ExSecrets.get("FOO") == "BAR"
    System.delete_env("FOO")
  end

  test "Get with Provider FOO - BAR" do
    System.put_env("FOOO", "BARR")
    assert ExSecrets.get("FOOO", :system_env) == "BARR"
    System.delete_env("FOOO")
  end

  test "Get with configuration FOO - BAR" do
    Application.put_env(:ex_secrets, :providers, [:xyz])
    System.put_env("FOOO", "BARR")
    assert ExSecrets.get("FOOO", :system_env) == "BARR"
    System.delete_env("FOOO")
  end
end
