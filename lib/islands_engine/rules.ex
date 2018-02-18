defmodule IslandsEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized, player1: :islands_not_set, player2: :islands_not_set

  @doc """
  New representation of rules for a game.
  """
  def new() do
    %Rules{}
  end

  @doc """
  Takes a state and an action.

  When we are in the :initialized state, it is OK to add a new player, and when
  that action happens, we should transition to :players_set state.
  """
  def check(%Rules{state: :initialized} = rules, :add_player) do
    {:ok, %Rules{rules | state: :players_set}}
  end

  @doc """
  When the game is in :players_set, it’s okay for either of the players to position
  their islands.

  If the value for the player key is :islands_not_set, it’s fine for that player
  to move her islands, so we return {:ok, rules}. If the values is :islands_set,
  it’s not okay for her to move her islands, so we return :error. Neither action
  is enough to transition the state out of :players_set, so we leave the rules
  struct alone
  """
  def check(%Rules{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end

  @doc """
  Always let a player position their islands, but we only transition to the state
  when both players have their islands set.
  """
  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)

    case both_players_islands_set?(rules) do
      true -> {:ok, %Rules{rules | state: :player1_turn}}
      false -> {:ok, rules}
    end
  end

  @doc """
  When its player1s turn, it is OK for player1 to guess a coordinate, and the state
  should transition to :player2_turn.
  """
  def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}) do
    {:ok, %Rules{rules | state: :player2_turn}}
  end

  @doc """
  Check if player1 wins and transition to :game_over if they do.
  """
  def check(%Rules{state: :player1_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  @doc """
  When its player2s turn, it is OK for player2 to guess a coordinate, and the state
  should transition to :player1_turn.
  """
  def check(%Rules{state: :player2_turn} = rules, {:guess_coordinate, :player2}) do
    {:ok, %Rules{rules | state: :player1_turn}}
  end

  @doc """
  Check if player2 wins and transition to :game_over if they do.
  """
  def check(%Rules{state: :player2_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  @doc """
  A catch-all for anything that does not match our whitelist of allowed actions.
  """
  def check(_state, _action) do
    :error
  end

  # Check if both players have their islands set
  defp both_players_islands_set?(rules) do
    rules.player1 == :islands_set && rules.player2 == :islands_set
  end
end
