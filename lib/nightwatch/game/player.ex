defmodule Nightwatch.Game.Player do
  use GenServer
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
  def start_link(name: name) do
    {:via, Registry, {Nightwatch.GameRegistry, id}} = name
    GenServer.start_link(__MODULE__, id, name: name)
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


  ##############################
  @spec init(String.t()) :: {:ok, Nightwatch.Game.Player.t() }
  def init(id) do
    Process.flag(:trap_exit, true)
    player =
      __MODULE__.__struct__(
        id: id,
        position: get_empty_pos()
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
    World.attack(state.id, state.position)
    {:noreply, state}
  end

  def handle_cast("kill", state) do
    World.kill_player(state.id)
    state = %{state | status: :dead}
    # Process.send_after(self(), {"respawn", state.id}, 5_000)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, _reason}, state) do
    {:noreply, state}
  end
  #############################
  @spec get_empty_pos :: {number(), number()}
  def get_empty_pos() do
    World.get_map()
    |> Enum.reduce([], fn {row_id, row_map}, acc ->
      empties = row_map
      |> Enum.filter(fn{_col, cell_value} -> cell_value === 1 end)
      |> Enum.map(fn {col_id, _cell_value} -> {row_id, col_id} end)
      [empties | acc]
    end)
    |> List.flatten()
    |> Enum.shuffle()
    |> List.first()
  end
end
