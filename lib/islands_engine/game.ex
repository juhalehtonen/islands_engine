defmodule IslandsEngine.Game do
  use GenServer
  alias IslandsEngine.{Board, Guesses, Rules}

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
end
