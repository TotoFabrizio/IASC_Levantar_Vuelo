defmodule Vuelos.VueloStore do
  use Agent

  alias Vuelos.Vuelo

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: via())
  end

  # Nombre global para que exista una sola instancia en todo el clúster
  def via, do: {:via, Horde.Registry, {Vuelos.Registry, :vuelo_store}}

  # --- Escritura ---

  def put(%Vuelo{} = flight) do
    Agent.update(via(), &Map.put(&1, flight.id, flight))
  end

  def delete(id) do
    Agent.update(via(), &Map.delete(&1, id))
  end

  # --- Lectura ---

  def get(id), do: Agent.get(via(), &Map.get(&1, id))

  def all, do: Agent.get(via(), &Map.values/1)

  def by_route(origin, destination) do
    Agent.get(via(), fn flights ->
      flights
      |> Map.values()
      |> Enum.filter(&(&1.origin == origin and &1.destination == destination))
    end)
  end

  def with_active_offer do
    now = DateTime.utc_now()

    Agent.get(via(), fn flights ->
      flights
      |> Map.values()
      |> Enum.filter(fn f ->
        f.offer_expires_at && DateTime.compare(now, f.offer_expires_at) == :lt
      end)
    end)
  end

  # --- Reserva atómica ---

  def reserve(id, type, qty) do
    Agent.get_and_update(via(), fn flights ->
      with %Vuelo{} = flight <- Map.get(flights, id),
           available when available >= qty <- Map.get(flight.seats, type, 0) do
        updated = put_in(flight.seats[type], available - qty)
        {:ok, Map.put(flights, id, updated)}
      else
        nil -> {{:error, :flight_not_found}, flights}
        _ -> {{:error, :not_enough_seats}, flights}
      end
    end)
  end
end
