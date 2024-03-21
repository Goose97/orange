defmodule Orange.MixProject do
  use Mix.Project

  # The CI workflow depends on this
  @version "0.1.0"
  @source_url "https://github.com/Goose97/orange"

  def project do
    [
      app: :orange,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      description: "A framework to build terminal UI applications in Elixir"
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

  defp package() do
    [
      maintainers: ["Nguyễn Văn Đức"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: [
        "lib",
        "native/orange_terminal_binding/.cargo",
        "native/orange_terminal_binding/src",
        "native/orange_terminal_binding/Cargo*",
        "checksum-*.exs",
        "mix.exs"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.31.0"},
      {:rustler_precompiled, "~> 0.7"},
      {:mox, "~> 1.1", only: :test},
      {:eflambe, "~> 0.3.0", only: :dev, runtime: false},
      {:benchee, "~> 1.3.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
