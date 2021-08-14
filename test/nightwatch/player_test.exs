defmodule Nightwatch.PlayerTest do

  alias Nightwatch.Game.Player
  alias Nightwatch.Helpers.Records
  use ExUnit.Case

  test "init" do
    {:ok, pid} = Player.start_link(name: Records.via_tuple("player"))
    assert is_pid(pid)
    state = Player.peek(Records.via_tuple("player"))

    assert state.id === "player"
    assert state.status === :alive
  end
end
