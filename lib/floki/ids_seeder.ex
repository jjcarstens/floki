defmodule Floki.IdsSeeder do
  use GenServer

  def start_link(default \\ []) do
    GenServer.start_link(__MODULE__, default)
  end

  def seed(pid) do
    GenServer.call(pid, :seed)
  end

  def ids(pid) do
    GenServer.call(pid, :ids)
  end

  ## GenServer API

  def handle_call(:seed, _from, state) do
    new_id = :crypto.strong_rand_bytes(4) |> Base.encode16

    {:reply, new_id, [new_id | state]}
  end

  def handle_call(:ids, _from, state) do
    {:reply, Enum.reverse(state), state}
  end
end
