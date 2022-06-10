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
end
