defmodule IslandsEngine.Board do
  @moduledoc """
  A players board contains his or her islands, but also brokers messages for them.
  """
  alias IslandsEngine.{Coordinate, Island}

  @doc """
  Create a new board.
  """
  def new() do
    %{}
  end

  @doc """
  If an island does not overlap an existing island on the board, we place it
  in the board map with the key we passed in.
  """
  def position_island(board, key, %Island{} = island) do
    case overlaps_existing_island?(board, key, island) do
      true -> {:error, :overlapping_island}
      false -> Map.put(board, key, island)
    end
  end

  # Check if a given island overlaps with an existing island.
  defp overlaps_existing_island?(board, new_key, new_island) do
    Enum.any?(board, fn {key, island} ->
      key != new_key and Island.overlaps?(island, new_island)
    end)
  end

  @doc """
  Check if all islands have been positioned by the player by comparing all available
  island types with the keys set on the board.
  """
  def all_islands_positioned?(board) do
    Enum.all?(Island.types(), &Map.has_key?(board, &1))
  end

  @doc """
  Takes a board map and a coordinate, and checks the board to see if that coordinate
  matches any in an island.

  The goal of the guess/2 function  is  to  reply  with  four  pieces  of  information:
  whether the guess was a hit or a miss, either :none or the type of island that
  was forested, :win or :no_win, and finally the board map itself.
  """
  def guess(board, %Coordinate{} = coordinate) do
    board
    |> check_all_islands(coordinate)
    |> guess_response(board)
  end

  # If a guess does result in a hit, we need to return both the island key and the
  # island itself.
  defp check_all_islands(board, coordinate) do
    Enum.find_value(board, :miss, fn {key, island} ->
      case Island.guess(island, coordinate) do
        {:hit, island} -> {key, island}
        :miss -> false
      end
    end)
  end

  defp guess_response({key, island}, board) do
    board = %{board | key => island}
    {:hit, forest_check(board, key), win_check(board), board}
  end

  # If we miss, we know we cannot win the game
  defp guess_response(:miss, board) do
    {:miss, :none, :no_win, board}
  end

  defp forest_check(board, key) do
    case forested?(board, key) do
      true -> key
      false -> :none
    end
  end

  defp forested?(board, key) do
    board
    |> Map.fetch!(key)
    |> Island.forested?()
  end

  defp win_check(board) do
    case all_forested?(board) do
      true -> :win
      false -> :no_win
    end
  end

  defp all_forested?(board) do
    Enum.all?(board, fn {_key, island} -> Island.forested?(island) end)
  end
end
