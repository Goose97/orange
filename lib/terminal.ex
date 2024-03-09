defmodule Orange.Terminal do
  @doc """
  Renders a buffer to the terminal. If previous_buffer is provided, it will only draw
  the diff between the two buffers
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

  defdelegate poll_event(), to: __MODULE__.Binding

  def enter_alternate_screen() do
    __MODULE__.Binding.enter_alternate_screen()
    :ok
  end

  def leave_alternate_screen() do
    __MODULE__.Binding.leave_alternate_screen()
    :ok
  end

  def enable_raw_mode() do
    __MODULE__.Binding.enable_raw_mode()
    :ok
  end

  def disable_raw_mode() do
    __MODULE__.Binding.disable_raw_mode()
    :ok
  end

  def show_cursor() do
    __MODULE__.Binding.show_cursor()
    :ok
  end

  def hide_cursor() do
    __MODULE__.Binding.hide_cursor()
    :ok
  end

  defdelegate terminal_size(), to: __MODULE__.Binding

  defmodule Binding do
    use Rustler, otp_app: :orange, crate: "orange_terminal_binding"

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
