defmodule Orange.Renderer.Style do
  @moduledoc false

  alias Orange.Layout.InputTreeNode

  # Converts style keywords to a binding style struct that can be passed to the layout engine.
  def to_binding_style(style, scroll_x \\ nil, scroll_y \\ nil)

  def to_binding_style(nil, _, _), do: nil

  def to_binding_style(style, scroll_x, scroll_y) do
    style = Map.new(style)

    border = expand_border(style, scroll_x, scroll_y)

    %InputTreeNode.Style{
      width: Map.get(style, :width) |> parse_length_percentage(),
      min_width: Map.get(style, :min_width) |> parse_length_percentage(),
      max_width: Map.get(style, :max_width) |> parse_length_percentage(),
      height: Map.get(style, :height) |> parse_length_percentage(),
      min_height: Map.get(style, :min_height) |> parse_length_percentage(),
      max_height: Map.get(style, :max_height) |> parse_length_percentage(),
      border: border,
      padding: Map.get(style, :padding) |> expand_padding_margin(),
      margin: Map.get(style, :margin) |> expand_padding_margin(),
      display: Map.get(style, :display, :flex),

      # Flex properties
      flex_direction: Map.get(style, :flex_direction),
      flex_grow: Map.get(style, :flex_grow),
      flex_shrink: Map.get(style, :flex_shrink),
      justify_content: Map.get(style, :justify_content),
      align_items: Map.get(style, :align_items),
      line_wrap: Map.get(style, :line_wrap, true),

      # Gap properties
      row_gap: Map.get(style, :row_gap) || Map.get(style, :gap),
      column_gap: Map.get(style, :column_gap) || Map.get(style, :gap),

      # Grid properties
      grid_template_rows: Map.get(style, :grid_template_rows) |> parse_grid_tracks(),
      grid_template_columns: Map.get(style, :grid_template_columns) |> parse_grid_tracks(),
      grid_auto_rows: Map.get(style, :grid_auto_rows) |> parse_grid_tracks(),
      grid_auto_columns: Map.get(style, :grid_auto_columns) |> parse_grid_tracks(),
      grid_row: Map.get(style, :grid_row) |> parse_grid_line_pair(),
      grid_column: Map.get(style, :grid_column) |> parse_grid_line_pair()
    }
  end

  # Inherits style properties from parent style.
  # Currently only inherits color and text_modifiers.
  def inherit_style(style, nil), do: style
  def inherit_style(nil, parent_style), do: inherit_style([], parent_style)

  def inherit_style(style, parent_style) do
    parent_color = parent_style[:color]
    parent_text_modifiers = parent_style[:text_modifiers]

    style = if parent_color, do: Keyword.put_new(style, :color, parent_color), else: style

    if parent_text_modifiers,
      do: Keyword.put_new(style, :text_modifiers, parent_text_modifiers),
      else: style
  end

  defp parse_length_percentage(size) do
    cond do
      is_integer(size) ->
        {:fixed, size}

      is_binary(size) and String.ends_with?(size, "%") ->
        {float, "%"} = Float.parse(size)
        {:percent, float / 100}

      size == nil ->
        nil
    end
  end

  defp expand_border(style, scroll_x, scroll_y) do
    # We render the scrollbar on top of the border. It means scroll_x implies border_bottom: true,
    # and scroll_y implies border_right: true
    scroll_bar_visible = Map.get(style, :scroll_bar, :visible) == :visible

    border_bottom = if scroll_x && scroll_bar_visible, do: 1
    border_right = if scroll_y && scroll_bar_visible, do: 1

    {
      border_position(style, :top),
      border_right || border_position(style, :right),
      border_bottom || border_position(style, :bottom),
      border_position(style, :left)
    }
  end

  @compile {:inline, border_position: 2}
  defp border_position(style, position) do
    attr_name =
      case position do
        :top -> :border_top
        :right -> :border_right
        :bottom -> :border_bottom
        :left -> :border_left
      end

    cond do
      (v = Map.get(style, attr_name)) != nil -> if v, do: 1, else: 0
      Map.get(style, :border) -> 1
      :else -> 0
    end
  end

  defp expand_padding_margin(value) do
    case value do
      {vy, vx} -> {vy, vx, vy, vx}
      {_top, _right, _bottom, _left} -> value
      0 -> nil
      v when is_integer(v) -> {v, v, v, v}
      _ -> nil
    end
  end

  defp parse_grid_tracks(nil), do: nil

  defp parse_grid_tracks(tracks) when is_list(tracks) do
    Enum.map(tracks, fn
      v when v in [:auto, :min_content, :max_content] ->
        v

      {:repeat, count, track} when is_integer(count) ->
        [track] = parse_grid_tracks([track])
        {:repeat, count, track}

      {:fr, v} when is_integer(v) ->
        {:fr, v}

      track ->
        # Otherwise, it must be fixed track
        size = parse_length_percentage(track)
        if size == nil, do: raise("Invalid grid track: #{inspect(track)}")
        size
    end)
  end

  defp parse_grid_line_pair(nil), do: nil

  # Single span
  defp parse_grid_line_pair({:span, span} = v) when is_integer(span), do: {:single, v}

  defp parse_grid_line_pair({start, end_}),
    do: {:double, parse_grid_line(start), parse_grid_line(end_)}

  defp parse_grid_line_pair(start), do: {:single, parse_grid_line(start)}

  defp parse_grid_line(line) when is_integer(line), do: {:fixed, line}
  defp parse_grid_line({:span, span}) when is_integer(span), do: {:span, span}
  defp parse_grid_line(:auto), do: :auto
end
