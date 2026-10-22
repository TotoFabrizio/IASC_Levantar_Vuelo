defmodule Vuelos.Vuelo do
  @enforce_keys [:id, :aircraft_type, :origin, :destination, :departure_at]
  defstruct [
    :id,
    :aircraft_type,                # "Tipo de avión", ej: "A320"
    :origin,                       # ej: "EZE"
    :destination,                  # ej: "MAD"
    :departure_at,                 # DateTime en UTC
    :offer_expires_at,             # DateTime en UTC (fin de la oferta)
    seats: %{ventana: 0, pasillo: 0, entre_asientos: 0}
  ]
end
