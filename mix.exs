defmodule IascHordeExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :iasc_elixir_horde_minimal_example,
      version: "0.2.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex, :wx, :observer, :runtime_tools],
      mod: {IascHordeExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.5"},
      {:horde, "~> 0.10"}
    ]
  end
end
