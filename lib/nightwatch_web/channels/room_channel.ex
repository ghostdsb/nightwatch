defmodule NightwatchWeb.RoomChannel do
  use Phoenix.Channel

  alias Nightwatch.Helpers.Records
  alias Nightwatch.Game.World
  alias Nightwatch.Game.Player

  @impl true
  def join("game:nw_mmo", params, socket) do
    Process.send_after(self(), {"after_join", params}, 10)
    {:ok, socket}
  end

  @impl true
  def handle_in("move", msg, socket) do
    # %{"dir" => %{"x" => -1, "y" => 0}, "id" => "player209"}
    move_direction = msg["dir"]
    Player.move(Records.via_tuple(msg["id"]), {move_direction["x"], move_direction["y"]})
    {:noreply, socket}
  end

  @impl true
  def handle_in("hit", msg, socket) do
    player_server = Records.via_tuple(msg["id"])
    position = msg["position"]
    Player.attack(player_server, {position["x"], position["y"]})
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    handle_terminate(socket)
  end

  @impl true
  def handle_info({"after_join", params}, socket) do
    DynamicSupervisor.start_child(Nightwatch.GameSupervisor, {Player, name: Records.via_tuple(params["userId"])})
    |> handle_player_start(params, socket)
    |> enter_player(params["userId"])
    {:noreply, socket}
  end

  def handle_terminate(socket) do
    case Records.is_process_registered(socket.assigns.user_id) do
      [] ->
        true
      _ ->
        Player.remove(Records.via_tuple(socket.assigns.user_id))
    end
  end

  def handle_player_start({:ok, _}, params, socket) do

    {x, y} = Player.get_pos(Records.via_tuple(params["userId"]))
    map = World.get_map()
    enemy_details =
      World.get_players()
      |> Enum.map(fn {player_id, _} ->
        {enemy_x, enemy_y} = Player.get_pos(Records.via_tuple(player_id))
        { player_id, %{x: enemy_x, y: enemy_y}}
      end)
      |> Map.new()

      broadcast!(socket, "player_joined", %{
      id: params["userId"],
      map: map,
      pos: %{x: x, y: y},
      players: enemy_details
    })
  end

  def handle_player_start({:error, {:already_started, _child}}, params, socket) do
    # :error
    {x, y} = Player.get_pos(Records.via_tuple(params["userId"]))
    map = World.get_map()
    enemy_details =
      World.get_players()
      |> Enum.map(fn {player_id, _} ->
        {enemy_x, enemy_y} = Player.get_pos(Records.via_tuple(player_id))
        { player_id, %{x: enemy_x, y: enemy_y}}
      end)
      |> Map.new()

      broadcast!(socket, "player_joined", %{
      id: params["userId"],
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
      World.player?(player_id) -> :ok
      true -> World.enter_player(player_id)
    end
  end

  def enter_player(:error, _player_id) do
    nil
  end
end
