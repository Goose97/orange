defmodule Orange.Renderer.Style do
  @moduledoc false

  alias Orange.Layout.InputTreeNode

  # Converts style keywords to a binding style struct that can be passed to the layout engine.
  def to_binding_style(style, scroll_x \\ nil, scroll_y \\ nil)

  def to_binding_style(nil, _, _), do: nil

  def to_binding_style(style, scroll_x, scroll_y) do
    border = expand_border(style)
    # We render the scrollbar on top of the border. It means scroll_x implies border_bottom: true,
    # and scroll_y implies border_right: true
    scroll_bar_visible = Keyword.get(style, :scroll_bar, :visible) == :visible
    border = if scroll_x && scroll_bar_visible, do: put_elem(border, 2, 1), else: border
    border = if scroll_y && scroll_bar_visible, do: put_elem(border, 1, 1), else: border

    %InputTreeNode.Style{
      width: parse_length_percentage(style[:width]),
      min_width: parse_length_percentage(style[:min_width]),
      max_width: parse_length_percentage(style[:max_width]),
      height: parse_length_percentage(style[:height]),
      min_height: parse_length_percentage(style[:min_height]),
      max_height: parse_length_percentage(style[:max_height]),
      border: border,
      padding: expand_padding_margin(style[:padding]),
      margin: expand_padding_margin(style[:margin]),
      display: Keyword.get(style, :display, :flex),

      # Flex properties
      flex_direction: style[:flex_direction],
      flex_grow: style[:flex_grow],
      flex_shrink: style[:flex_shrink],
      justify_content: style[:justify_content],
      align_items: style[:align_items],
      line_wrap: Keyword.get(style, :line_wrap, true),

      # Gap properties
      row_gap: style[:row_gap] || style[:gap],
      column_gap: style[:column_gap] || style[:gap],

      # Grid properties
      grid_template_rows: parse_grid_tracks(style[:grid_template_rows]),
      grid_template_columns: parse_grid_tracks(style[:grid_template_columns]),
      grid_auto_rows: parse_grid_tracks(style[:grid_auto_rows]),
      grid_auto_columns: parse_grid_tracks(style[:grid_auto_columns]),
      grid_row: parse_grid_line_pair(style[:grid_row]),
      grid_column: parse_grid_line_pair(style[:grid_column])
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

  defp expand_border(style) do
    border = fn position ->
      border_value =
        if style[:"border_#{position}"] != nil,
          do: style[:"border_#{position}"],
          else: style[:border]

      if border_value, do: 1, else: 0
    end

    {border.(:top), border.(:right), border.(:bottom), border.(:left)}
  end

  defp expand_padding_margin(value) do
    case value do
      {vy, vx} -> {vy, vx, vy, vx}
      {_top, _right, _bottom, _left} -> value
      v when is_integer(v) -> {v, v, v, v}
      nil -> {0, 0, 0, 0}
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
