defmodule NightwatchWeb.RoomChannel do
  use Phoenix.Channel

  alias Nightwatch.Helpers.Records
  alias Nightwatch.Game.World
  alias Nightwatch.Game.Player

  @impl true
  def join("game:nw_mmo", params, socket) do
    Process.send_after(self(), {"after_join", params}, 1000)
    {:ok, socket}
  end

  @impl true
  def handle_in("move", msg, socket) do
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
    World.spawn_player(params["userId"])
    {:noreply, socket}
  end

  defp handle_terminate(socket) do
    case Records.is_process_registered(socket.assigns.user_id) do
      [] ->
        true
      _ ->
        World.remove_player(socket.assigns.user_id)
    end
  end
end
