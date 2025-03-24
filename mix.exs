defmodule Orange.MixProject do
  use Mix.Project

  # The CI workflow depends on this
  @version "0.5.0"
  @source_url "https://github.com/Goose97/orange"

  def project do
    [
      app: :orange,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      docs: docs(),
      aliases: aliases(),
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

  defp docs() do
    [
      main: "Orange",
      extras: [
        "guides/events-subscription.md"
      ],
      groups_for_modules: [
        Components: [
          Orange.Component,
          Orange.Component.Input,
          Orange.Component.Modal,
          Orange.Component.TabBar,
          Orange.Component.List
        ],
        Events: [
          Orange.Terminal.KeyEvent,
          Orange.Terminal.ResizeEvent
        ],
        Test: [
          Orange.Test,
          Orange.Test.Assertions,
          Orange.Test.Snapshot
        ]
      ]
    ]
  end

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
        "native/orange_layout_binding/.cargo",
        "native/orange_layout_binding/src",
        "native/orange_layout_binding/Cargo*",
        "checksum-*.exs",
        "mix.exs"
      ]
    ]
  end

  defp aliases() do
    [docs: ["docs", &copy_images/1]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.36.0"},
      {:rustler_precompiled, "~> 0.8"},
      {:eflambe, "~> 0.3.0", only: :dev, runtime: false},
      {:benchee, "~> 1.3.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:logger_file_backend, "~> 0.0.14", only: [:dev, :test]}
    ]
  end

  defp copy_images(_) do
    File.rm_rf!("doc/assets")

    File.cp_r!("assets", "doc/assets", fn source, destination ->
      IO.gets("Overwriting #{destination} by #{source}. Type y to confirm. ") == "y\n"
    end)
  end
end
