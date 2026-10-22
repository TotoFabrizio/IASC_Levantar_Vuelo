defmodule Alertas.Alerta do
  @enforce_keys [:id, :month, :origin, :destination, :persona]
  defstruct [
    :id,
    :month,                        # ej: "3"
    :origin,                       # ej: "EZE"
    :destination,                  # ej: "MAD"
    :persona                       # ej: "Pedro"
  ]
end
