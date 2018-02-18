defmodule IslandsEngine.Game do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient
  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}
  @players [:player1, :player2]
  # Timeout a GenServer after a day if no messages are received
  @timeout 60 * 60 * 24 * 1000

  ## Client API

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
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

  @doc """
  Guess a coordinate.
  """
  def guess_coordinate(game, player, row, col) when player in @players do
    GenServer.call(game, {:guess_coordinate, player, row, col})
  end

  ## Server callbacks

  @doc """
  Initialize a game with two players and a set of rules. The first player has the
  name but the second player is left anonymous until he or she joins up.
  """
  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}, @timeout}
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
      :error -> {:reply, :error, state_data, @timeout}
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
      :error ->
        {:reply, :error, state_data, @timeout}

      {:error, :invalid_coordinate} ->
        {:reply, {:error, :invalid_coordinate}, state_data, @timeout}

      {:error, :invalid_island_type} ->
        {:reply, {:error, :invalid_island_type}, state_data, @timeout}

      {:error, :overlapping_island} ->
        {:reply, {:error, :overlapping_island}, state_data, @timeout}
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
      :error -> {:reply, :error, state_data, @timeout}
      false -> {:reply, {:error, :not_all_islands_positioned}, state_data, @timeout}
    end
  end

  @doc """
  Handle call for guessing a coordinate. We need to check whether..:
  - The rules allow the given player to guess?
  - The row and column values make a valid coordinate?
  - The guess was a hit or a miss, whether it forested an island, and whether it won the game?
  - The state should transition to game over?
  """
  def handle_call({:guess_coordinate, player_key, row, col}, _from, state_data) do
    opponent_key = opponent(player_key)
    opponent_board = player_board(state_data, opponent_key)

    with {:ok, rules} <- Rules.check(state_data.rules, {:guess_coordinate, player_key}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, opponent_board} <-
           Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do
      state_data
      |> update_board(opponent_key, opponent_board)
      |> update_guesses(player_key, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_success({hit_or_miss, forested_island, win_status})
    else
      :error ->
        {:reply, :error, state_data, @timeout}

      {:error, :invalid_coordinate} ->
        {:reply, {:error, :invalid_coordinate}, state_data, @timeout}
    end
  end

  @doc """
  Handle timeouts and shut down the GenServer by returning a :stop tuple.
  """
  def handle_info(:timeout, state_data) do
    {:stop, {:shutdown, :timeout}, state_data}
  end

  ## Helpers

  @doc """
  Helper to return the :via tuple required by a process Registry.
  """
  def via_tuple(name) do
    {:via, Registry, {Registry.Game, name}}
  end

  defp update_player2_name(state_data, name) do
    put_in(state_data.player2.name, name)
  end

  # Simply use the map update syntax to update rules
  defp update_rules(state_data, rules) do
    %{state_data | rules: rules}
  end

  # Create a reply for successful calls
  defp reply_success(state_data, reply) do
    {:reply, reply, state_data, @timeout}
  end

  # Get individual player board
  defp player_board(state_data, player) do
    Map.get(state_data, player).board
  end

  # Update individual board
  defp update_board(state_data, player, board) do
    Map.update!(state_data, player, fn player -> %{player | board: board} end)
  end

  # Update guesses of given player
  defp update_guesses(state_data, player_key, hit_or_miss, coordinate) do
    update_in(state_data[player_key].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  # Get opponent of given player
  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1
end
