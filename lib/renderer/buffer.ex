defmodule Orange.Renderer.Buffer do
  @moduledoc false

  # All rendering should be done through a buffer. A buffer is a 2D array of cells

  alias Orange.Renderer

  defstruct [
    :size,
    rows: []
  ]

  # Fixed size buffer
  def new({width, height}) do
    default_row = :array.new(width, fixed: true)
    rows = :array.new(height, default: default_row, fixed: true)
    %__MODULE__{rows: rows, size: {width, height}}
  end

  # Dynamic size buffer
  def new() do
    default_row = :array.new(0, fixed: false)
    rows = :array.new(0, default: default_row, fixed: false)
    %__MODULE__{rows: rows, size: nil}
  end

  def write_string(_buffer, _coordinate, _text, _direction, opts \\ [])

  def write_string(buffer, {x, y}, text, :horizontal, opts)
      when is_struct(buffer, __MODULE__) do
    String.graphemes(text)
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {char, index}, acc ->
      buffer_write(acc, {x + index, y}, char, opts)
    end)
  end

  def write_string(buffer, {x, y}, text, :vertical, opts)
      when is_struct(buffer, __MODULE__) do
    String.graphemes(text)
    |> Enum.with_index()
    |> Enum.reduce(buffer, fn {char, index}, acc ->
      buffer_write(acc, {x, y + index}, char, opts)
    end)
  end

  def get_cell(%__MODULE__{rows: rows}, {x, y}) do
    row = :array.get(y, rows)
    :array.get(x, row)
  end

  def write_cell(buffer, {x, y}, %Renderer.Cell{} = cell) do
    row_to_update = :array.get(y, buffer.rows)
    updated_row = :array.set(x, cell, row_to_update)
    %{buffer | rows: :array.set(y, updated_row, buffer.rows)}
  end

  def clear_area(buffer, %Renderer.Area{width: 0}), do: buffer
  def clear_area(buffer, %Renderer.Area{height: 0}), do: buffer

  def clear_area(%{size: {width, height}} = buffer, %Renderer.Area{x: x, y: y})
      when x >= width
      when y >= height,
      do: buffer

  def clear_area(buffer, %Renderer.Area{} = area) do
    {buffer_width, buffer_height} = buffer.size || {nil, nil}

    Enum.reduce(0..(area.height - 1), buffer, fn i, acc ->
      if !buffer_height || area.y + i < buffer_height do
        row_to_update = :array.get(area.y + i, acc.rows)

        updated_row =
          Enum.reduce(0..(area.width - 1), row_to_update, fn j, row ->
            if !buffer_width || area.x + j < buffer_width do
              :array.set(area.x + j, :array.default(row), row)
            else
              row
            end
          end)

        %{acc | rows: :array.set(area.y + i, updated_row, acc.rows)}
      else
        acc
      end
    end)
  end

  defp buffer_write(%__MODULE__{size: {width, height}} = buffer, {x, y}, text, opts) do
    cond do
      y >= height or y < 0 ->
        buffer

      x >= width or x < 0 ->
        buffer

      true ->
        cell = %Renderer.Cell{
          character: text,
          foreground: opts[:color],
          background: opts[:background_color],
          modifiers: Keyword.get(opts, :text_modifiers, [])
        }

        write_cell(buffer, {x, y}, cell)
    end
  end

  defp buffer_write(%__MODULE__{size: nil} = buffer, {x, y}, text, opts) do
    cell = %Renderer.Cell{
      character: text,
      foreground: opts[:color],
      background: opts[:background_color],
      modifiers: Keyword.get(opts, :text_modifiers, [])
    }

    write_cell(buffer, {x, y}, cell)
  end

  def set_background_color(buffer, %Renderer.Area{} = area, color)
      when is_struct(buffer, __MODULE__) do
    Enum.reduce(0..(area.height - 1), buffer, fn i, acc ->
      Enum.reduce(0..(area.width - 1), acc, fn j, acc ->
        set_cell_background_color(acc, {area.x + j, area.y + i}, color)
      end)
    end)
  end

  defp set_cell_background_color(buffer, {x, y}, color) do
    cond do
      buffer.size && x >= elem(buffer.size, 0) ->
        buffer

      buffer.size && y >= elem(buffer.size, 1) ->
        buffer

      true ->
        row_to_update = :array.get(y, buffer.rows)
        cell = :array.get(x, row_to_update)

        updated_row =
          case cell do
            :undefined ->
              new_cell = %Renderer.Cell{background: color}
              :array.set(x, new_cell, row_to_update)

            %Orange.Renderer.Cell{background: nil} ->
              updated_cell = %Orange.Renderer.Cell{cell | background: color}
              :array.set(x, updated_cell, row_to_update)

            # Already has a background color
            _ ->
              row_to_update
          end

        %{buffer | rows: :array.set(y, updated_row, buffer.rows)}
    end
  end

  def to_string(%__MODULE__{rows: rows}, opts \\ []) do
    empty_char = Keyword.get(opts, :empty_char, "-")

    :array.to_list(rows)
    |> Enum.map(fn row ->
      for cell <- :array.to_list(row) do
        case cell do
          :undefined -> empty_char
          %Orange.Renderer.Cell{character: char} -> char
        end
      end
    end)
    |> Enum.join("\n")
  end

  def get_color(%__MODULE__{} = buffer, x, y) do
    cell = get_cell(buffer, {x, y})
    cell.foreground
  end

  def get_background_color(%__MODULE__{} = buffer, x, y) do
    cell = get_cell(buffer, {x, y})
    cell.background
  end

  def get_modifiers(%__MODULE__{} = buffer, x, y) do
    cell = get_cell(buffer, {x, y})
    cell.modifiers
  end

  def size(%__MODULE__{size: nil} = buffer) do
    content_height = :array.size(buffer.rows)

    content_width =
      Enum.map(1..content_height, fn i ->
        case :array.get(i, buffer.rows) do
          :undefined -> 0
          row -> :array.size(row)
        end
      end)
      |> Enum.max()

    {content_width, content_height}
  end

  def size(%__MODULE__{size: size}), do: size
end
