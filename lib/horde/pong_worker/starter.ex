defmodule IascHordeExample.PongWorker.Starter do
  @moduledoc """
  Module in charge of starting and monitoring  the `PongWorker`
  process, restarting it when necessary.
  """
  alias CustomIASC.{HordeRegistry, HordeSupervisor}
  alias IascHordeExample.{PongWorker}

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary,
      shutdown: 500
    }
  end

  def start_link(opts) do
    name =
      opts
      |> Keyword.get(:name, Elixir.PongWorker)
      |> via_tuple()

    opts = Keyword.put(opts, :name, name)

    child_spec = %{
      id: PongWorker,
      start: {PongWorker, :start_link, [opts]}
    }

    HordeSupervisor.start_child(child_spec)

    :ignore
  end

  def whereis(name \\ PongWorker) do
    name
    |> via_tuple()
    |> GenServer.whereis()
  end

  def via_tuple(name) do
    {:via, Horde.Registry, {HordeRegistry, name}}
  end
end
