defmodule IslandsEngine.Island do
  @moduledoc """
  Represents different islands and their coordinates & hit coordinates.
  """
  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  @doc """
  Take the island type and the upper left coordinate.

  There are two conditions that a new island needs to meet:
  1) The offsets function has to return a list of offsets instead of an error,
  2) add_coordinates needs to return a MapSet instead of an error.

  If both conditions are met, we return a tuple with a new Island struct.
  """
  def new(type, %Coordinate{} = upper_left) do
    with [_ | _] = offsets <- offsets(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, upper_left) do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  # We use reduce_while to validate our island positions, as we need to make sure
  # that the island cannot overflow the board.
  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      add_coordinate(acc, upper_left, offset)
    end)
  end

  # Take the set of coordinates, the upper-left coordinate, and the offset tuple.
  # Each time we build a new coordinate, we check to see if it is valid. If it is, we
  # use MapSet.put/2 to add the new coordinate to the set and return it in the tagged
  # :cont tuple. If the coordinate is invalid, we return {:halt, {:error, :invalid_coordinate}}
  # to stop the enumeration. The error tuple will bubble up through add_coordinates/2
  # to the original caller
  defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} ->
        {:cont, MapSet.put(coordinates, coordinate)}

      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end

  # Different offsets for different shapes, with coordinate lists starting from
  # the top left corner of each shape.
  defp offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  defp offsets(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]
  defp offsets(:dot), do: [{0, 0}]
  defp offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]
  defp offsets(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]
  defp offsets(_), do: {:error, :invalid_island_type}
end
