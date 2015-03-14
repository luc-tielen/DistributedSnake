defmodule Snake.Tile do
  use GenServer
  use Snake.Game
  alias Snake.TileDB
  alias Snake.GUI

  @moduledoc """
  Tile process corresponds with one {X, Y} coordinate, exposes interfaces to
  the GUI.
  """

  # Geen manager nodig, alleen ETS tabel aangemaakt door sup, 
  # slaat pids op per node per coordinaat
  # tiles zelf plaatsen hun eigen in die tabel

  defmodule State do
    @default_value quote do: throw "argument not defined!"
    defstruct table: @default_value,
              x: @default_value, 
              y: @default_value,
              occupied_with: :no_pid
  end

  # API

  @doc """
  Starts a tile process at location {X, Y}.
  """
  def start_link(args = %{table: table, x: x, y: y}) 
      when is_integer(table) and is_integer(x) and is_integer(y)
      and x > -1 and x < width and y > -1 and y < height do
    GenServer.start_link(__MODULE__, args)
  end

  @doc """
  Notifies the tile process that the snake has arrived.
  """
  def notify_arrival(tile, :snake, pid, color) when is_pid(tile) 
                                                and is_pid(pid)
                                                and is_atom(color) do
    :ok = tile |> GenServer.call {:notify_arrival, :snake, pid, color}
  end

  @doc """
  Notifies the tile process that the insect has arrived.
  """
  def notify_arrival(tile, :insect, pid) when is_pid(tile) 
                                        and is_pid(pid) do
    :ok = tile |> GenServer.call {:notify_arrival, :insect, pid}
  end

  @doc """
  Notifies the tile process that the snake or insect has left this coordinate.
  """
  def notify_gone(tile, pid) when is_pid(tile) and is_pid(pid) do
    :ok = tile |> GenServer.call {:notify_gone, pid}
  end

  # GenServer callbacks

  @doc false
  def init(%{table: table, x: x, y: y}) do
    table |> TileDB.add({x, y}, self)
    {:ok, %State{table: table, x: x, y: y}}
  end

  @doc false
  def handle_call({:notify_arrival, :snake, pid, color}, _from, 
                  state = %State{x: x, y: y, occupied_with: :no_pid}) do
    GUI.draw_snake %{x: x, y: y, node: node, color: color}
    {:reply, :ok, %State{state | occupied_with: pid}}
  end
  def handle_call({:notify_arrival, :snake, _pid, _color}, _from,
                  state = %State{occupied_with: pid}) do
    {:reply, {:occupied_with, pid}, state}
  end
  def handle_call({:notify_arrival, :insect, pid}, _from, 
                  state = %State{x: x, y: y, occupied_with: :no_pid}) do
    GUI.draw_insect %{x: x, y: y, node: node}
    {:reply, :ok, %State{state | occupied_with: pid}}
  end
  def handle_call({:notify_arrival, :insect, _pid}, _from,
                  state = %State{occupied_with: pid}) do
    {:reply, {:occupied_with, pid}, state}
  end
  def handle_call({:notify_gone, pid}, _from, 
                  state = %State{occupied_with: pid}) do
    {:reply, :ok, %State{state | occupied_with: :no_pid}}
  end
  def handle_call({:notify_gone, _pid1}, _from, 
                  state = %State{occupied_with: _pid2}) do
    {:reply, {:error, :not_allowed}, state}
  end
  def handle_call(_request, _from, state) do
    {:reply, {:error, :not_supported}, state}
  end

  @doc false
  def terminate(_reason, %State{table: table, x: x, y: y}) do
    table |> TileDB.delete {x, y}
    :ok
  end
end