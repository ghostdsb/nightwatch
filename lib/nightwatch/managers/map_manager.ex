defmodule Nightwatch.Manager.MapManager do

  # prepare the map from json file in priv folder
  @spec get_map :: map
  def get_map() do
    grid =
      File.read!("priv/map.json")
      |> Jason.decode!()

    make_map(grid["map"])
  end

  # get an empty cell on the map
  @spec get_empty_pos(map()) :: tuple()
  def get_empty_pos(map) do
    map
    |> Enum.reduce([], fn {row_id, row_map}, acc ->
      empties = row_map
      |> Enum.filter(fn{_col, cell_value} -> cell_value === 1 end)
      |> Enum.map(fn {col_id, _cell_value} -> {col_id, row_id} end)
      [empties | acc]
    end)
    |> List.flatten()
    |> Enum.shuffle()
    |> List.first()
  end

  defp make_map(map) do
    map
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {row, row_id}, acc ->
      Map.put(acc, row_id, row |> convert_to_tile_map)
    end)
  end

  defp convert_to_tile_map(tile_list) do
    tile_list
    |> Enum.with_index()
    |> Enum.map(fn {tile, col_id} -> {col_id, tile} end)
    |> Map.new()
  end


end
