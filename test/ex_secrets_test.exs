defmodule ExSecretsTest do
  use ExUnit.Case
  doctest ExSecrets

  test "greets the world" do
    assert ExSecrets.hello() == :world
  end
end
