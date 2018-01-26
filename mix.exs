defmodule Rosetta.MixProject do
  use Mix.Project

  def project do
    [
      app: :rosetta,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      escript: escript_config()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:excoveralls, github: "parroty/excoveralls"}
    ]
  end

  defp escript_config do
    [ main_module: GeoTIFF.CLI ]
  end
end
