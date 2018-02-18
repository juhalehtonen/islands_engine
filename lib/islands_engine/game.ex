defmodule IslandsEngine.Game do
  use GenServer
  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}
  @players [:player1, :player2]

  ## Client API

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, [])
  end

  @doc """
  Add a new player to an existing game.
  """
  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  @doc """
  Position an island on a game.
  """
  def position_island(game, player, key, row, col) when player in @players do
    GenServer.call(game, {:position_island, player, key, row, col})
  end

  @doc """
  Set islands. Islands are marked as set when player is done positioning them.
  """
  def set_islands(game, player) when player in @players do
    GenServer.call(game, {:set_islands, player})
  end

  ## Server callbacks

  @doc """
  Initialize a game with two players and a set of rules. The first player has the
  name but the second player is left anonymous until he or she joins up.
  """
  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}}
  end

  @doc """
  Handle the call to add a new player to the game by updating the player name,
  updating the rules, and sending a reply back to the caller.
  """
  def handle_call({:add_player, name}, _from, state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player) do
      state_data
      |> update_player2_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state_data}
    end
  end

  @doc """
  Handle the call to position an island.

  For success, we need to check a number of conditions:
  • that the rules permit players to position their islands
  • that the row and col values generate a valid coordinate
  • that the island key and the upper-left coordinate generate a valid island
  • that positioning the island doesn’t generate an error
  """
  def handle_call({:position_island, player, key, row, col}, _from, state_data) do
    board = player_board(state_data, player)

    with {:ok, rules} <- Rules.check(state_data.rules, {:position_islands, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(key, coordinate),
         %{} = board <- Board.position_island(board, key, island) do
      state_data
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state_data}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state_data}
      {:error, :invalid_island_type} -> {:reply, {:error, :invalid_island_type}, state_data}
    end
  end

  @doc """
  Handle call for setting islands.
  """
  def handle_call({:set_islands, player}, _from, state_data) do
    board = player_board(state_data, player)

    with {:ok, rules} <- Rules.check(state_data.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board) do
      state_data
      |> update_rules(rules)
      |> reply_success({:ok, board})
    else
      :error -> {:reply, :error, state_data}
      false -> {:reply, {:error, :not_all_islands_positioned}, state_data}
    end
  end

  ## Helpers

  defp update_player2_name(state_data, name) do
    put_in(state_data.player2.name, name)
  end

  # Simply use the map update syntax to update rules
  defp update_rules(state_data, rules) do
    %{state_data | rules: rules}
  end

  # Create a reply for successful calls
  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end

  # Get individual player board
  defp player_board(state_data, player) do
    Map.get(state_data, player).board
  end

  # Update individual board
  defp update_board(state_data, player, board) do
    Map.update!(state_data, player, fn player -> %{player | board: board} end)
  end
end
