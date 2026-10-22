defmodule IascHordeExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: MinimalExample.ClusterSupervisor]]}, #libcluster


      Supervisor.child_spec({CustomIASC.HordeRegistry, [name: Vuelos.Registry]}, id: :vuelos_registry),
      Supervisor.child_spec({CustomIASC.HordeRegistry, [name: Alertas.Registry]}, id: :alertas_registry),

      # https://hexdocs.pm/horde/Horde.UniformQuorumDistribution.html
      {CustomIASC.HordeSupervisor,
        [strategy: :one_for_one,
        distribution_strategy: Horde.UniformQuorumDistribution,
        process_redistribution: :active
      ]
        },

      CustomIASC.NodeObserver.Supervisor, # node supervisor. Not from Horde

      {Task, fn ->
        for store <- [Vuelos.VueloStore, Alertas.AlertaStore] do
          case Horde.DynamicSupervisor.start_child(CustomIASC.HordeSupervisor, store) do
            {:ok, _pid} -> :ok
            {:error, {:already_started, _pid}} -> :ok
            other -> IO.inspect(other, label: "start_child #{inspect(store)}")
          end
        end
      end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html for other strategies and supported options
    opts = [strategy: :one_for_one, name: IascHordeExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp topologies do
    # https://hexdocs.pm/libcluster/Cluster.Strategy.Epmd.html
    [
      horde_minimal_example: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: [:node1@altair]],
      ]
    ]
  end
end
