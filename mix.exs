defmodule Orange.MixProject do
  use Mix.Project

  # The CI workflow depends on this
  @version "0.1.0"

  def project do
    [
      app: :orange,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.31.0"},
      {:mox, "~> 1.1", only: :test},
      {:eflambe, "~> 0.3.0", only: :dev},
      {:benchee, "~> 1.3.0", only: :dev}
    ]
  end
end
