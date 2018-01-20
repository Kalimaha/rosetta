defmodule RosettaTest do
  use ExUnit.Case
  doctest Rosetta

  test "greets the world" do
    assert Rosetta.hello() == :world
  end
end
