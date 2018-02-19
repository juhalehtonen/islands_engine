defmodule IslandsEngine.GameTest do
  use ExUnit.Case
  alias IslandsEngine.Game

  setup _context do
    name = "Lena"
    via = Game.via_tuple(name)
    [via: via, name: name]
  end

  test "Attempting to start two games of the same name fails", context do
    GenServer.start_link(Game, context[:name], name: context[:via])
    assert {:error, _} = GenServer.start_link(Game, context[:name], name: context[:via])
  end

  test "Attempting to start one game with unique name succeeds", context do
    assert {:ok, _} = GenServer.start_link(Game, context[:name], name: context[:via])
  end

  test "Attempting to guess right after starting a new game fails" do
    {:ok, game} = Game.start_link("Miles")
    assert :error = Game.guess_coordinate(game, :player1, 1, 1)
  end

  test "Adding a new player to a game with one player succeeds" do
    {:ok, game} = Game.start_link("Dack")
    assert :ok = Game.add_player(game, "Trane")
  end

  test "Attempting to position an island right after starting a new game fails" do
    {:ok, game} = Game.start_link("Rambo")
    assert :error = Game.position_island(game, :player1, :dot, 1, 1)
  end

  test "Player 1 positioning an island when two players are in game succeeds" do
    {:ok, game} = Game.start_link("Jack")
    Game.add_player(game, "Trane")
    assert :ok = Game.position_island(game, :player1, :dot, 1, 1)
  end

  test "Player 2 positioning an island when two players are in game fails" do
    {:ok, game} = Game.start_link("Jacke")
    Game.add_player(game, "Traner")
    assert :ok = Game.position_island(game, :player2, :dot, 1, 1)
  end
end
