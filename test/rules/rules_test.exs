defmodule IslandsEngine.RulesTest do
  use ExUnit.Case
  alias IslandsEngine.Rules

  test "Creating new rules succeeds and returns in :initialized state" do
    assert %Rules{state: :initialized} = Rules.new()
  end

  test "Adding a new player when in :initialized state succeeds" do
    rules = Rules.new()
    assert {:ok, _rules} = Rules.check(rules, :add_player)
  end

  test "Attempting a completely wrong action in :initialized state fails" do
    rules = Rules.new()
    assert :error = Rules.check(rules, :fail_everything)
  end

  test "Attempting to add a new player when in :players_set state" do
    rules = %Rules{state: :players_set}
    assert :error = Rules.check(rules, :add_player)
  end
end
