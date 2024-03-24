defmodule Orange.Terminal do
  @moduledoc """
  Provides API to interact with the terminal.
  """

  alias Orange.Renderer.{Cell, Buffer}
  alias Orange.Terminal.KeyEvent

  @callback draw(buffer :: Buffer.t()) :: :ok
  @callback draw(buffer :: Buffer.t(), previous_buffer :: Buffer.t()) :: :ok
  @callback poll_event() :: [KeyEvent.t()]
  @callback enter_alternate_screen() :: :ok
  @callback leave_alternate_screen() :: :ok
  @callback enable_raw_mode() :: :ok
  @callback disable_raw_mode() :: :ok
  @callback show_cursor() :: :ok
  @callback hide_cursor() :: :ok
  @callback terminal_size() :: {non_neg_integer(), non_neg_integer()}

  def draw(buffer, previous_buffer \\ nil)

  @doc """
  Draws the buffer to the terminal. If a previous buffer is provided, it will only draw the diff between the two buffers.
  """
  def draw(buffer, nil) do
    cells =
      buffer.rows
      |> :array.to_list()
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, row_index} ->
        row
        |> :array.to_list()
        |> Enum.with_index()
        |> Enum.map(fn
          {:undefined, _} -> nil
          {cell, col_index} -> {cell, col_index, row_index}
        end)
        |> Enum.reject(&is_nil/1)
      end)

    __MODULE__.Binding.draw(cells)
    :ok
  end

  def draw(buffer, previous_buffer) do
    diff_cells =
      buffer.rows
      |> :array.to_list()
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, row_index} ->
        row
        |> :array.to_list()
        |> Enum.with_index()
        |> Enum.map(fn {new_cell, col_index} ->
          old_cell = :array.get(col_index, :array.get(row_index, previous_buffer.rows))

          case {old_cell, new_cell} do
            {same_cell, same_cell} -> nil
            {_, :undefined} -> {%Cell{character: " "}, col_index, row_index}
            {_, cell} -> {cell, col_index, row_index}
          end
        end)
        |> Enum.reject(&is_nil/1)
      end)

    __MODULE__.Binding.draw(diff_cells)
    :ok
  end

  @doc """
  Polls the terminal for events.
  """
  defdelegate poll_event(), to: __MODULE__.Binding

  @doc """
  Enter terminal alternate screen.
  """
  def enter_alternate_screen() do
    __MODULE__.Binding.enter_alternate_screen()
    :ok
  end

  @doc """
  Leave terminal alternate screen.
  """
  def leave_alternate_screen() do
    __MODULE__.Binding.leave_alternate_screen()
    :ok
  end

  @doc """
  Enable terminal raw mode.
  """
  def enable_raw_mode() do
    __MODULE__.Binding.enable_raw_mode()
    :ok
  end

  @doc """
  Disable terminal raw mode.
  """
  def disable_raw_mode() do
    __MODULE__.Binding.disable_raw_mode()
    :ok
  end

  @doc """
  Show terminal cursor.
  """
  def show_cursor() do
    __MODULE__.Binding.show_cursor()
    :ok
  end

  @doc """
  Hide terminal cursor.
  """
  def hide_cursor() do
    __MODULE__.Binding.hide_cursor()
    :ok
  end

  defdelegate terminal_size(), to: __MODULE__.Binding

  defmodule Binding do
    @moduledoc false

    use RustlerPrecompiled,
      otp_app: :orange,
      crate: "orange_terminal_binding",
      base_url: "https://github.com/Goose97/orange/releases/download/v0.2.0",
      version: "0.2.0",
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

    def draw(_buffer), do: :erlang.nif_error(:nif_not_loaded)
    def enter_alternate_screen(), do: :erlang.nif_error(:nif_not_loaded)
    def leave_alternate_screen(), do: :erlang.nif_error(:nif_not_loaded)
    def enable_raw_mode(), do: :erlang.nif_error(:nif_not_loaded)
    def disable_raw_mode(), do: :erlang.nif_error(:nif_not_loaded)
    def show_cursor(), do: :erlang.nif_error(:nif_not_loaded)
    def hide_cursor(), do: :erlang.nif_error(:nif_not_loaded)
    def poll_event(), do: :erlang.nif_error(:nif_not_loaded)
    def terminal_size(), do: :erlang.nif_error(:nif_not_loaded)
  end
end
