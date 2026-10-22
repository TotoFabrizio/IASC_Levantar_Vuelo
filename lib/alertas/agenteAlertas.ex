defmodule Alertas.AlertaStore do
  use Agent

  alias Alertas.Alerta

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: via())
  end

  # Nombre global para que exista una sola instancia en todo el clúster
  def via, do: {:via, Horde.Registry, {Alerta.Registry, :flight_store}}

  # --- Escritura ---

  def put(%Alerta{} = flight) do
    Agent.update(via(), &Map.put(&1, flight.id, flight))
  end

  def delete(id) do
    Agent.update(via(), &Map.delete(&1, id))
  end

  # --- Lectura ---

  def get(id), do: Agent.get(via(), &Map.get(&1, id))

  def all, do: Agent.get(via(), &Map.values/1)
end
