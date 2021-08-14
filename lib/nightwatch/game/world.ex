defmodule Nightwatch.Game.World do
  use GenServer, restart: :transient

  alias Nightwatch.Manager.MapManager
  alias Nightwatch.Helpers.Records
  alias Nightwatch.Game.Player

  @type t :: %Nightwatch.Game.World{
    grid: map(),
    game_map: map(),
    players: map()
  }

  defstruct(
    grid: %{},
    game_map: %{},
    players: %{}
  )

  ###############################
  @spec start_link(any()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_map() do
    GenServer.call(__MODULE__, "get_map")
  end

  def get_players() do
    GenServer.call(__MODULE__, "get_players")
  end

  def empty?(coord) do
    GenServer.call(__MODULE__, {"is_empty", coord})
  end

  def player?(player_id) do
    GenServer.call(__MODULE__, {"player_present", player_id})
  end

  def enter_player(player_id) do
    GenServer.cast(__MODULE__, {"enter_player", player_id})
  end

  def remove_player(player_id) do
    GenServer.cast(__MODULE__, {"remove_player", player_id})
  end

  def kill_player(player_id) do
    GenServer.cast(__MODULE__, {"kill_player", player_id})
  end

  def attack(player_id, position) do
    GenServer.cast(__MODULE__, {"attack", player_id, position})
  end

  ##############################
  def init(:ok) do

    {:ok, %{
      grid: MapManager.get_map(),
      game_map: MapManager.get_map(),
      players: %{}
    }}
  end

  def handle_call("get_map", _from, state) do
    {:reply, state.game_map, state}
  end

  def handle_call("get_players", _from, state) do
    {:reply, state.players, state}
  end

  def handle_call({"is_empty", {x,y}}, _from, state) do
    {:reply, get_cell(state.game_map[y][x]), state}
  end

  def handle_call({"player_present", player_id}, _from, state) do
    {:reply, Map.has_key?(state.players, player_id), state}
  end

  def handle_cast({"enter_player", player_id}, state) do
    process = Records.via_tuple(player_id)
    Process.monitor(GenServer.whereis(process))
    state = %{state | players: Map.update(state.players, player_id, 1, &(&1+1))}
    {:noreply, state}
  end


  def handle_cast({"remove_player", player_id}, state) do

    state = case Map.get(state.players, player_id) do
      1 ->
        process = Records.via_tuple(player_id)
        Process.exit(GenServer.whereis(process), :kill)

        NightwatchWeb.Endpoint.broadcast!("game:nw_mmo", "player_terminated", %{
          id: player_id,
          })
        %{state | players: Map.delete(state.players, player_id)}

      _ ->
          %{state | players: Map.update(state.players, player_id, 1, &{&1-1})}
    end

      {:noreply, state}

  end

  def handle_cast({"kill_player", player_id}, state) do

    state = %{state | players: Map.delete(state.players, player_id)}
    process = Records.via_tuple(player_id)
    Process.exit(GenServer.whereis(process), :kill)

    Process.send_after(self(), {"respawn", player_id}, 5_000)

    NightwatchWeb.Endpoint.broadcast!("game:nw_mmo", "player_terminated", %{
      id: player_id,
      })
    {:noreply, state}

  end

  def handle_cast({"attack", player_id, attack_position}, state) do
    state.players
    |> Enum.map(fn {enemy_id, _} ->
      {enemy_id, Player.get_pos(Records.via_tuple(enemy_id))}
    end)
    |> Enum.filter(fn {enemy_id, player_pos} -> affected?(player_pos, attack_position, enemy_id, player_id) end)
    |> Enum.each(fn {enemy_id, _pos} ->  Player.kill(Records.via_tuple(enemy_id)) end)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, _pid, _reason}, state) do

    {:noreply, state}
  end

  def handle_info({"respawn", player_id}, state) do
    DynamicSupervisor.start_child(Nightwatch.GameSupervisor, {Player, name: Records.via_tuple(player_id)})
    |> handle_player_start(player_id, state)
    |> enter_player_after_respawn(state, player_id)

    {:noreply, state}
  end


  #############################

  defp get_cell(nil), do: false
  defp get_cell(0), do: false
  defp get_cell(1), do: true

  defp affected?({player_x, player_y}, {player_x, player_y}, player_id, player_id) do
    false
  end
  defp affected?({player_x, player_y}, {attack_x, attack_y}, _enemy, _player) do
    abs(player_x-attack_x) <= 1 && abs(player_y-attack_y) <= 1
  end

  def handle_player_start({:ok, _}, player_id, state) do

    {x, y} = Player.get_pos(Records.via_tuple(player_id))
    map = MapManager.get_map()
    enemy_details =
      state.players
      |> Enum.map(fn {player_id, _} ->
        {enemy_x, enemy_y} = Player.get_pos(Records.via_tuple(player_id))
        { player_id, %{x: enemy_x, y: enemy_y}}
      end)
      |> Map.new()

      NightwatchWeb.Endpoint.broadcast!("game:nw_mmo", "player_joined", %{
      id: player_id,
      map: map,
      pos: %{x: x, y: y},
      players: enemy_details
    })
  end

  def handle_player_start({:error, {:already_started, _child}}, player_id, state) do
    :error
    {x, y} = Player.get_pos(Records.via_tuple(player_id))
    map = MapManager.get_map()
    enemy_details =
      state.players
      |> Enum.map(fn {player_id, _} ->
        {enemy_x, enemy_y} = Player.get_pos(Records.via_tuple(player_id))
        { player_id, %{x: enemy_x, y: enemy_y}}
      end)
      |> Map.new()

      NightwatchWeb.Endpoint.broadcast!("game:nw_mmo", "player_joined", %{
      id: player_id,
      map: map,
      pos: %{x: x, y: y},
      players: enemy_details
    })
  end

  def handle_player_start(_rest, _params, _socket) do
    :ok
  end

  def enter_player(:ok, player_id) do
    cond do
      player?(player_id) -> :ok
      true -> enter_player(player_id)
    end
  end

  def enter_player(:error, _player_id) do
    nil
  end

  def enter_player_after_respawn(:ok, state, player_id) do
    cond do
      Map.has_key?(state.players, player_id) -> :ok
      true -> enter_player(player_id)
    end
  end

  def enter_player_after_respawn(:error, _state, _player_id) do
    nil
  end
end
