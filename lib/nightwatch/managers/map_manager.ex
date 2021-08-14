defmodule Nightwatch.Manager.MapManager do

  def get_map() do
    grid =
      File.read!("priv/map.json")
      |> Jason.decode!()

    make_map(grid["map"])
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
