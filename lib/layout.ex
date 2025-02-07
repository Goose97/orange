defmodule Orange.Layout do
  @moduledoc false

  defdelegate layout(tree, window_size), to: __MODULE__.Binding

  defmodule Binding do
    @moduledoc false

    use RustlerPrecompiled,
      otp_app: :orange,
      crate: "orange_layout_binding",
      base_url: "https://github.com/Goose97/orange/releases/download/v0.5.0",
      version: "0.5.0",
      targets: [
        "arm-unknown-linux-gnueabihf",
        "aarch64-unknown-linux-gnu",
        "aarch64-unknown-linux-musl",
        "aarch64-apple-darwin",
        "riscv64gc-unknown-linux-gnu",
        "x86_64-apple-darwin",
        "x86_64-unknown-linux-gnu",
        "x86_64-unknown-linux-musl",
        "x86_64-pc-windows-gnu",
        "x86_64-pc-windows-msvc"
      ],
      nif_versions: ["2.15", "2.16"]

    def layout(_tree, _window_size), do: :erlang.nif_error(:nif_not_loaded)
  end
end
