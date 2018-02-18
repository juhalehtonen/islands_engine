defmodule IslandsEngine.Guesses do
  @moduledoc """
  Represent the guesses made against the 'opponents' board. We can ignore the
  coordinates that are not hits or misses, are those are just the ocean.
  """
  alias __MODULE__
  @enforce_keys [:hits, :misses]
  defstruct [:hits, :misses]

  @doc """
  Returns a new Guesses struct. Uses MapSet data structure that guarantees that
  each member of the MapSet will be unique, as we must be sure that we dont have
  multiple guesses on the same coordinates.
  """
  def new() do
    %Guesses{hits: MapSet.new(), misses: MapSet.new()}
  end
end
