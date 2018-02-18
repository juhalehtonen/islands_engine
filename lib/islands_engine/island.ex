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

  @doc """
  Guess a coordinate.

  If a guessed coordinate is a member of the coordinates set, we need to transform
  the island by adding the coordinate to the hit coordinates set, and then return
  a tuple containing :hit and the transformed island.

  If the guessed coordinate is not in the coordinates set, we don need to do any
  transformation and we can just return :miss.
  """
  def guess(island, coordinate) do
    case MapSet.member?(island.coordinates, coordinate) do
      true ->
        hit_coordinates = MapSet.put(island.hit_coordinates, coordinate)
        {:hit, %{island | hit_coordinates: hit_coordinates}}

      false ->
        :miss
    end
  end

  @doc """
  Check if an island is fully forested by checking if all coordinates of the island
  have been hit.
  """
  def forested?(island) do
    MapSet.equal?(island.coordinates, island.hit_coordinates)
  end

  @doc """
  Return the list of valid types. Used to check if all valid types have been positioned.
  """
  def types() do
    [:atoll, :dot, :l_shape, :s_shape, :square]
  end

  @doc """
  Check if an existing island overlaps with a new island by using MapSet.disjoint?.
  Disjointed MapSets share no members.
  """
  def overlaps?(existing_island, new_island) do
    not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)
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
