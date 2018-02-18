defmodule IslandsEngine.Coordinate do
  @moduledoc """
  Represents (x and y) coordinates on the game board.

  Because we alias the module itself here, we can refer to coordinates as
  %Coordinate{} instead of %IslandsEngine.Coordinate{}.
  """
  alias __MODULE__
  @board_range 1..10
  @enforce_keys [:row, :col]
  defstruct [:row, :col]

  @doc """
  Add a new coordinate point to given row and column,requiring both to be in the
  range of our 10x10 board.
  """
  def new(row, col) when row in @board_range and col in @board_range do
    {:ok, %Coordinate{row: row, col: col}}
  end

  def new(_row, _col) do
    {:error, :invalid_coordinate}
  end
end
