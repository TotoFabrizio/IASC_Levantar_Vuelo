defmodule CustomIASC.NodeObserver do
  use GenServer
  require Logger

  alias CustomIASC.HordeSupervisor

  @registries [Vuelos.Registry, Alertas.Registry]

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl GenServer
  def init(state) do
    # https://erlang.org/doc/man/net_kernel.html#monitor_nodes-1
    :net_kernel.monitor_nodes(true, node_type: :visible)

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:nodedown, node, _node_type}, state) do
    Logger.info("---- Node down: #{node} ----")
    update_all_members()
    {:noreply, state}
  end

  def handle_info({:nodeup, node, _node_type}, state) do
    Logger.info("---- Node up: #{node} ----")
    update_all_members()
    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp update_all_members do
    for name <- @registries ++ [HordeSupervisor] do
      set_members(name)
    end
  end

  defp set_members(name) do
    nodes =
      [Node.self() | Node.list()]
      |> Enum.reject(&observer_node?/1)

    members = Enum.map(nodes, &{name, &1})

    :ok = Horde.Cluster.set_members(name, members)
  end

  defp observer_node?(node) do
    node |> Atom.to_string() |> String.starts_with?("observer@")
  end
end
