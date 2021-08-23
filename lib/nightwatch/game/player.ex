defmodule Nightwatch.Game.Player do
  use GenServer, restart: :transient
  alias Nightwatch.Game.World

  @type t :: %Nightwatch.Game.Player{
    id: String.t(),
    status: :alive|:dead,
    position: tuple(),
  }

  defstruct(
    id: "",
    status: :alive,
    position: {0,0}
  )

  ###############################
  def start_link([name: name, pos: pos]) do
    {:via, Registry, {Nightwatch.GameRegistry, id}} = name
    GenServer.start_link(__MODULE__, [id, pos], name: name)
  end

  @spec get_pos(atom | pid | {atom, any} | {:via, atom, any}) :: {number(), number()}
  def get_pos(name) do
    GenServer.call(name, "get_pos")
  end
  def peek(name) do
    GenServer.call(name, "peek")
  end

  @spec move(atom | pid | {atom, any} | {:via, atom, any}, any) :: :ok
  def move(name, dir) do
    GenServer.cast(name, {"move", dir})
  end

  def remove(name) do
    GenServer.cast(name, "remove")
  end

  def kill(name) do
    GenServer.cast(name, "kill")
  end

  def attack(name, position) do
    GenServer.cast(name, {"attack", position})
  end

  def stop_player_process(name) do
    GenServer.cast(name, "stop")
  end


  ##############################
  def init([id, pos]) do
    Process.flag(:trap_exit, true)
    player =
      __MODULE__.__struct__(
        id: id,
        position: pos
      )

    {:ok, player}
  end

  def handle_call("get_pos", _from, state) do
    {:reply, state.position, state}
  end

  def handle_call("peek", _from, state) do
    {:reply, state, state}
  end

  def handle_cast({"move", {x,y}}, state) do
    {pos_x, pos_y} = state.position
    new_pos = cond do
      state.status == :dead ->
        state.position
      World.empty?({pos_x+x, pos_y+y}) ->
        NightwatchWeb.Endpoint.broadcast!("game:nw_mmo", "move", %{
          id: state.id,
          position: %{
            x: pos_x+x,
            y: pos_y+y,
          }
        })
        {pos_x+x, pos_y+y}
      true -> {pos_x, pos_y}
    end
    state = %{state | position: new_pos}
    {:noreply, state}
  end

  def handle_cast("remove", state) do
    World.remove_player(state.id)
    {:noreply, state}
  end

  def handle_cast({"attack", _position}, state) do
    case state.status do
      :alive ->
        World.attack(state.id, state.position)
      _ ->
        nil
    end
    {:noreply, state}
  end

  def handle_cast("kill", state) do
    World.kill_player(state.id)
    state = %{state | status: :dead}
    {:noreply, state}
  end

  def handle_info({:EXIT, _, _reason}, state) do
    {:stop, :normal,  state}
  end

  def handle_info({:DOWN, _, _, _reason}, state) do
    {:noreply, state}
  end
end
