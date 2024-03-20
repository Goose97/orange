defmodule Orange.Renderer do
  @moduledoc false

  alias __MODULE__.Buffer
  alias Orange.{CustomComponent, Rect, Line, Span, Cursor}

  @type window :: %{width: integer, height: integer}
  @type style_chain :: [Keyword.t()]
  @type ui_element :: Orange.Rect.t() | Orange.Line.t() | Orange.Span.t()

  # We need to render the elements to a buffer before painting them to the screen
  # A buffer a just a m x n matrix of characters
  @spec render(ui_element, window) :: Buffer.t()
  def render(element, window) do
    width = window[:width]
    height = window[:height]
    buffer = Buffer.new({width, height})

    viewport = %__MODULE__.Area{x: 0, y: 0, width: width, height: height}
    render_tree = to_render_tree(element)
    validate_render_tree!(render_tree)
    render_root(render_tree, viewport, buffer)
  end

  # Convert a element tree to a tree of Renderer.Box
  defp to_render_tree(element) do
    case element do
      %CustomComponent{children: [child]} ->
        to_render_tree(child)

      %Rect{attributes: attrs, children: children} ->
        title = attrs[:title]
        style = Keyword.get(attrs, :style, [])

        {padding, style} = Keyword.pop(style, :padding)
        padding = if padding, do: expand_padding(padding), else: {0, 0, 0, 0}

        {width, style} = Keyword.pop(style, :width)
        {height, style} = Keyword.pop(style, :height)

        scroll_x = attrs[:scroll_x]
        scroll_y = attrs[:scroll_y]

        %__MODULE__.Box{
          children: Enum.map(children, &to_render_tree/1),
          padding: padding,
          border: border_attribute(style, title),
          width: width,
          height: height,
          style: style,
          layout_direction: Keyword.get(attrs, :direction, :column),
          title: title,
          scroll: if(scroll_x || scroll_y, do: {scroll_x, scroll_y})
        }

      %Line{attributes: attrs, children: children} ->
        style = Keyword.get(attrs, :style, [])

        {padding, style} = Keyword.pop(style, :padding)
        padding = if padding, do: expand_padding(padding), else: {0, 0, 0, 0}

        {width, style} = Keyword.pop(style, :width)
        {height, style} = Keyword.pop(style, :height)

        %__MODULE__.Box{
          children: Enum.map(children, &to_render_tree/1),
          padding: padding,
          border: nil,
          width: width,
          height: height,
          style: style,
          layout_direction: :row
        }

      %Span{attributes: attrs, children: [text]} ->
        style = Keyword.get(attrs, :style, [])

        %__MODULE__.Box{
          children: text,
          padding: {0, 0, 0, 0},
          border: nil,
          style: style
        }
    end
  end

  defp border_attribute(style, title) do
    has_border = Keyword.get(style, :border, false) || title != nil

    if has_border do
      {Keyword.get(style, :border_top, true), Keyword.get(style, :border_right, true),
       Keyword.get(style, :border_bottom, true), Keyword.get(style, :border_left, true)}
    else
      nil
    end
  end

  defp validate_render_tree!(root) do
    validate_fractional_size = fn type ->
      # Don't validate custom components
      has_fraction_size =
        Enum.any?(root.children, fn child ->
          size = Map.get(child, type)
          size && is_binary(size) && Regex.match?(~r/^\d+fr$/, size)
        end)

      if has_fraction_size do
        all_has_fraction_size =
          Enum.all?(root.children, fn child ->
            size = Map.get(child, type)
            size && is_binary(size) && Regex.match?(~r/^\d+fr$/, size)
          end)

        if !all_has_fraction_size do
          raise "#{__MODULE__}: Fractional #{type} must be set for all children"
        end
      end
    end

    case root do
      %__MODULE__.Box{children: children} when is_list(children) ->
        validate_fractional_size.(:width)
        validate_fractional_size.(:height)
        Enum.each(children, &validate_render_tree!/1)

      _ ->
        :ok
    end
  end

  # Renders the render tree to a buffer
  # The box layout algorithm is as follows:
  # - Boxes will be rendered top-down
  # - Children boxes has two layout mode: row and column
  # - A box has two interesting areas: the outer area and the inner area
  #   * The outer area is the area that the box occupies in the screen. This will be used to render
  #     the border and the background color. The outer area COULD be partial, specifically missing width or
  #     height. For example if the box width and height is not specified, these dimensions will be
  #     determined by the children areas.
  #   * The inner area is the area that the children MIGHT occupy. This area is affected by the padding
  #     and the border. The inner area is ALWAYS complete (in constract to the outer area) and the children
  #     of the box MUST NOT exceed this area.
  #   * Notice that the inner area might be bigger than the outer area, because it's the potential
  #     area that the children MIGHT occupy. Whereas the outer area is the actual area that the box
  #     occupies in the screen
  #
  # - The outer area will be calculated as follows:
  #   * The root box outer area is the whole screen
  #   * If the width or height is specified, the outer area will has the specified width and height
  #   * If the width or height is not specified, such dimension will be calculated based on the children
  # - The inner area will be calculated as follows:
  #   * If the outer area is complete, the inner area will be the outer area minus the padding
  #     and the border, if any
  #   * If the outer area is not complete, a hypothetical outer area will be calculated based on the
  #     inner area of the parent. The hypothetical area represents the maximum area that this box
  #     could occupy. The inner area will then be calculated based on this hypothetical area
  @spec render_root(
          __MODULE__.Box.t(),
          __MODULE__.Area.t(),
          Buffer.t()
        ) :: Buffer.t()
  defp render_root(root, viewport, buffer) do
    outer_area = %__MODULE__.Area{x: 0, y: 0}
    root = %{root | outer_area: outer_area}
    {buffer, _} = render_one(root, nil, viewport, buffer, [])

    buffer
  end

  defp merge_scrollable_children(buffer, scrollable_buffer, parent) do
    # We extract the area which is visible in the viewport
    {scroll_x, scroll_y} = parent.scroll

    children_viewport =
      extract_buffer_viewport(
        scrollable_buffer,
        scroll_x || 0,
        scroll_y || 0,
        parent.inner_area.width,
        parent.inner_area.height
      )

    Enum.with_index(children_viewport)
    |> Enum.reduce(buffer, fn {row, row_index}, acc ->
      Enum.with_index(row)
      |> Enum.reduce(acc, fn {cell, col_index}, acc ->
        if cell != :undefined do
          Buffer.write_cell(
            acc,
            {parent.inner_area.x + col_index, parent.inner_area.y + row_index},
            cell
          )
        else
          acc
        end
      end)
    end)
  end

  defp extract_buffer_viewport(buffer, x, y, width, height) do
    buffer.rows
    |> :array.to_list()
    |> Enum.slice(y, height)
    |> Enum.map(fn row ->
      :array.to_list(row) |> Enum.slice(x, width)
    end)
  end

  defp assert_scrollable_box_has_sizes!(box) do
    if box.outer_area.width == nil do
      raise "#{__MODULE__}: Width is required for scrollable box"
    end

    if box.outer_area.height == nil do
      raise "#{__MODULE__}: Height is required for scrollable box"
    end

    box
  end

  # Scrollable box
  # The render algorithm is as follows:
  # 1. First render the scrollable children into a separate buffer. This buffer is not limited in sizes
  # (width and height are set to :infinity)
  # 2. Extract the visible area from the children buffer. This area is determined by the scroll offset (x, y) and
  # the width and height of the parent inner box
  # 3. Merge the visible area into the parent buffer
  defp render_scroll(%__MODULE__.Box{scroll: scroll} = box, parent, viewport, buffer, style_chain)
       when scroll != nil do
    new_buffer = Buffer.new()

    # The inner area of the scrollable box is guaranteed to be complete
    {scroll_x, scroll_y} = scroll

    outer_area = %__MODULE__.Area{
      x: 0,
      y: 0,
      width: box.inner_area.width,
      height: box.inner_area.height
    }

    inner_area = outer_area
    inner_area = if scroll_x, do: %{inner_area | width: :infinity}, else: inner_area
    inner_area = if scroll_y, do: %{inner_area | height: :infinity}, else: inner_area

    # We render the children separately. To do that, we wrap them inside a plain box
    plain_box = %__MODULE__.Box{
      children: box.children,
      layout_direction: box.layout_direction,
      padding: {0, 0, 0, 0},
      border: false,
      style: [],
      outer_area: outer_area,
      inner_area: inner_area
    }

    {new_buffer, _after_render_box} = render_one(plain_box, nil, nil, new_buffer, style_chain)

    box =
      box
      |> set_box_outer_area(parent, viewport)
      |> assert_scrollable_box_has_sizes!()
      |> set_box_inner_area(parent, viewport)

    buffer = merge_scrollable_children(buffer, new_buffer, box)
    buffer = post_render_styling(box, buffer)
    {buffer, box}
  end

  defp render_one(%__MODULE__.Box{} = box, parent, viewport, buffer, style_chain) do
    style_chain = [box.style | style_chain]

    box = set_box_outer_area(box, parent, viewport)
    box = if box.inner_area == nil, do: set_box_inner_area(box, parent, viewport), else: box

    {buffer, after_render_box} =
      cond do
        is_binary(box.children) ->
          render_leaf(box, buffer, style_chain)

        box.children == [] ->
          {buffer, box}

        box.scroll != nil ->
          render_scroll(box, parent, viewport, buffer, style_chain)

        is_list(box.children) ->
          children = maybe_calculate_fraction_sizes(box.children, box.inner_area)

          %{box | children: children}
          |> render_many(buffer, style_chain, box.layout_direction)
      end

    buffer = post_render_styling(after_render_box, buffer)
    {buffer, after_render_box}
  end

  # Render the following:
  # - borders
  # - title
  # - background color
  defp post_render_styling(box, buffer) do
    buffer = if box.border, do: render_border(box, buffer), else: buffer
    buffer = if box.title, do: render_title(box, buffer), else: buffer

    if box.style[:background_color] do
      # Background color includes the padding but not the border
      Buffer.set_background_color(
        buffer,
        inner_area(
          box.outer_area,
          {0, 0, 0, 0},
          box.border
        ),
        box.style[:background_color]
      )
    else
      buffer
    end
  end

  defp set_box_outer_area(box, parent, viewport) do
    # TODO: Assert that total_area is complete
    # Meaning that if we use percentage width/height for the children, the parent must have
    # specified width/height
    total_area = if parent, do: parent.inner_area, else: viewport

    outer_area = box.outer_area

    outer_area =
      if box.width && !outer_area.width do
        if total_area.width == :infinity and not is_integer(box.width) do
          raise "#{__MODULE__}: Horizontal scroll boxes only support children with integer width, instead got #{box.width}"
        end

        %{outer_area | width: calculate_size(box.width, total_area.width)}
      else
        outer_area
      end

    outer_area =
      if box.height && !outer_area.height do
        if total_area.height == :infinity and not is_integer(box.height) do
          raise "#{__MODULE__}: Vertical scroll boxes only support children with integer height, instead got #{box.height}"
        end

        %{outer_area | height: calculate_size(box.height, total_area.height)}
      else
        outer_area
      end

    %{box | outer_area: outer_area}
  end

  defp set_box_inner_area(box, parent, viewport) do
    outer_area = box.outer_area

    # First, inner_area will be calculated based on the hypothetical max outer area
    # If width/height of the outer_area is specified, the inner_area can be bounded by the measures
    # The hypothetical outer area of the root is the viewport
    hypothetical_max_outer =
      if parent,
        do: hypothetical_outer_area(outer_area, parent),
        else: %{outer_area | width: viewport.width, height: viewport.height}

    inner_area = inner_area(hypothetical_max_outer, box.padding, box.border)

    inner_area =
      if outer_area.width do
        # width is bounded
        %{width: width} = inner_area(outer_area, box.padding, box.border)
        %{inner_area | width: width}
      else
        inner_area
      end

    inner_area =
      if outer_area.height do
        # height is bounded
        %{height: height} = inner_area(outer_area, box.padding, box.border)
        %{inner_area | height: height}
      else
        inner_area
      end

    %{box | inner_area: inner_area}
  end

  defp inner_area(outer_area, padding, border) do
    {top, right, bottom, left} = padding
    %__MODULE__.Area{x: x, y: y, width: width, height: height} = outer_area

    width =
      case width do
        :infinity -> :infinity
        width when width != nil -> width - left - right
        _ -> nil
      end

    height =
      case height do
        :infinity -> :infinity
        height when height != nil -> height - top - bottom
        _ -> nil
      end

    area = %__MODULE__.Area{
      x: x + left,
      y: y + top,
      width: width,
      height: height
    }

    if border do
      {top_border, _right, _bottom, left_border} = border
      x = if left_border, do: area.x + 1, else: area.x
      y = if top_border, do: area.y + 1, else: area.y

      {horizontal, vertical} = border_sizes(border)

      width =
        case area.width do
          :infinity -> :infinity
          width when width != nil -> width - horizontal
          _ -> nil
        end

      height =
        case area.height do
          :infinity -> :infinity
          height when height != nil -> height - vertical
          _ -> nil
        end

      %__MODULE__.Area{
        x: x,
        y: y,
        width: width,
        height: height
      }
    else
      area
    end
  end

  defp hypothetical_outer_area(outer_area, %__MODULE__.Box{
         inner_area: %{width: :infinity, height: :infinity}
       }),
       do: %{outer_area | width: :infinity, height: :infinity}

  defp hypothetical_outer_area(outer_area, parent) do
    width =
      case parent.inner_area.width do
        :infinity ->
          :infinity

        width when width != nil ->
          w = width - (outer_area.x - parent.inner_area.x)
          max(w, 0)

        _ ->
          nil
      end

    height =
      case parent.inner_area.height do
        :infinity ->
          :infinity

        height when height != nil ->
          h = height - (outer_area.y - parent.inner_area.y)
          max(h, 0)

        _ ->
          nil
      end

    %{outer_area | width: width, height: height}
  end

  def render_leaf(
        %__MODULE__.Box{children: text, style: style} = box,
        buffer,
        style_chain
      ) do
    style_chain = [style | style_chain]

    # This box is overflown from the parent, hence the zero height or width
    if box.inner_area.height == 0 || box.inner_area.width == 0 do
      box = %{box | outer_area: %{box.outer_area | width: 0, height: 0}}
      {buffer, box}
    else
      opts = [
        color: get_style(style_chain, :color),
        background_color: style[:background_color],
        text_modifiers: get_style(style_chain, :text_modifiers) || []
      ]

      text =
        if box.inner_area.width && box.inner_area.width != :infinity,
          do: String.slice(text, 0, box.inner_area.width),
          else: text

      new_buffer =
        Buffer.write_string(buffer, {box.inner_area.x, box.inner_area.y}, text, :horizontal, opts)

      box = %{box | width: String.graphemes(text) |> length(), height: 1}
      box = %{box | outer_area: %{box.outer_area | width: box.width, height: box.height}}
      {new_buffer, box}
    end
  end

  def render_many(%__MODULE__.Box{children: children} = box, buffer, style_chain, direction) do
    cursor = %Cursor{x: box.inner_area.x, y: box.inner_area.y}

    {buffer, rendered_children, _} =
      Enum.reduce(children, {buffer, [], cursor}, fn child,
                                                     {buffer, rendered_children, current_cursor} ->
        partial_outer_area = %__MODULE__.Area{x: current_cursor.x, y: current_cursor.y}
        child = %{child | outer_area: partial_outer_area}

        {buffer, after_render_child} =
          render_one(child, box, nil, buffer, [box.style | style_chain])

        new_cursor =
          case direction do
            :row -> move_cursor_x(current_cursor, after_render_child.outer_area.width)
            :column -> move_cursor_y(current_cursor, after_render_child.outer_area.height)
          end

        {buffer, rendered_children ++ [after_render_child], new_cursor}
      end)

    # Fill in the outer area with sizes calculated from the children
    bounding_area = Enum.map(rendered_children, & &1.outer_area) |> bounding_areas()

    outer_area = box.outer_area

    outer_area =
      if !outer_area.width do
        {_top, right, _bottom, left} = box.padding
        width = bounding_area.width + left + right

        width =
          if box.border do
            {border_horizontal, _border_vertical} = border_sizes(box.border)
            width + border_horizontal
          else
            width
          end

        %{outer_area | width: width}
      else
        outer_area
      end

    outer_area =
      if !outer_area.height do
        {top, _right, bottom, _left} = box.padding
        height = bounding_area.height + top + bottom

        height =
          if box.border do
            {_border_horizontal, border_vertical} = border_sizes(box.border)
            height + border_vertical
          else
            height
          end

        %{outer_area | height: height}
      else
        outer_area
      end

    box = %{box | outer_area: outer_area}
    {buffer, box}
  end

  defp border_sizes({top, right, bottom, left}) do
    horizontal = if(left, do: 1, else: 0) + if(right, do: 1, else: 0)
    vertical = if(top, do: 1, else: 0) + if(bottom, do: 1, else: 0)

    {horizontal, vertical}
  end

  defp expand_padding(padding) do
    case padding do
      {py, px} -> {py, px, py, px}
      {_top, _right, _bottom, _left} -> padding
      padding when is_integer(padding) -> {padding, padding, padding, padding}
    end
  end

  defp get_style(style_chain, key) do
    style = Enum.find(style_chain, fn item -> Keyword.get(item, key) end)
    if style, do: Keyword.get(style, key)
  end

  defp calculate_size(size, total_size) do
    cond do
      is_integer(size) ->
        size

      result = Regex.run(~r/^calc\((.+)\)$/, size) ->
        expr = Enum.at(result, 1)

        evaluate_size_expr(expr, total_size)

      result = Regex.run(~r/^(\d+)%$/, size) ->
        (String.to_integer(Enum.at(result, 1)) * total_size)
        |> div(100)
    end
  end

  defp evaluate_size_expr(expr, total_size) do
    {value, _} =
      Regex.replace(~r/(\d+)%/, expr, fn _, match ->
        {float, _} = Float.parse(match)
        to_string(float * total_size / 100)
      end)
      |> Code.eval_string()

    round(value)
  end

  defp maybe_calculate_fraction_sizes(boxes, total_area) do
    calculate_fractional_size = fn boxes, type ->
      all_use_fraction_size? =
        Enum.all?(boxes, fn box ->
          size = Map.get(box, type)
          size && is_binary(size) && Regex.match?(~r/^\d+fr$/, size)
        end)

      if all_use_fraction_size? do
        box_fractions =
          Enum.map(boxes, fn box ->
            size = Map.get(box, type)
            fraction = Regex.run(~r/^(\d+)fr$/, size) |> Enum.at(1)

            {box, String.to_integer(fraction)}
          end)

        sum_fraction = Enum.map(box_fractions, &elem(&1, 1)) |> Enum.sum()

        new_sizes =
          Enum.map(box_fractions, fn {box, fraction} ->
            size = (fraction / sum_fraction * Map.get(total_area, type)) |> round()
            {box, size}
          end)

        # To avoid rounding error, the last box size will be the remaining
        total =
          Enum.slice(new_sizes, 0, length(new_sizes) - 1) |> Enum.map(&elem(&1, 1)) |> Enum.sum()

        remaining = Map.get(total_area, type) - total
        new_sizes = put_in(new_sizes, [Access.at(-1), Access.elem(1)], remaining)

        Enum.map(new_sizes, fn {box, size} -> Map.put(box, type, size) end)
      else
        boxes
      end
    end

    boxes
    |> calculate_fractional_size.(:width)
    |> calculate_fractional_size.(:height)
  end

  defp move_cursor_x(%Orange.Cursor{} = cursor, amount), do: %{cursor | x: cursor.x + amount}
  defp move_cursor_y(%Orange.Cursor{} = cursor, amount), do: %{cursor | y: cursor.y + amount}

  defp render_border(box, buffer) do
    %__MODULE__.Area{x: x, y: y, width: width, height: height} = box.outer_area
    color = box.style[:border_color]

    {top, right, bottom, left} = box.border

    # Top border
    buffer =
      if top do
        top_border =
          if(left, do: "┌", else: "─") <>
            String.duplicate("─", width - 2) <>
            if(right, do: "┐", else: "─")

        Buffer.write_string(buffer, {x, y}, top_border, :horizontal, color: color)
      else
        buffer
      end

    # Bottom border
    buffer =
      if bottom do
        bottom_border =
          if(left, do: "└", else: "─") <>
            String.duplicate("─", width - 2) <>
            if(right, do: "┘", else: "─")

        Buffer.write_string(buffer, {x, y + height - 1}, bottom_border, :horizontal, color: color)
      else
        buffer
      end

    # Left and right border
    start = if top, do: y + 1, else: y
    stop = if bottom, do: y + height - 2, else: y + height - 1
    length = stop - start + 1
    vertical_border = String.duplicate("│", length)

    buffer =
      if left do
        Buffer.write_string(buffer, {x, start}, vertical_border, :vertical, color: color)
      else
        buffer
      end

    buffer =
      if right do
        Buffer.write_string(buffer, {x + width - 1, start}, vertical_border, :vertical,
          color: color
        )
      else
        buffer
      end

    buffer
  end

  defp render_title(box, buffer) do
    Buffer.write_string(
      buffer,
      {box.outer_area.x + 1, box.outer_area.y},
      box.title,
      :horizontal
    )
  end

  # Given a list of areas, return the smallest area which contains all the areas
  defp bounding_areas(areas) do
    left = Enum.map(areas, fn %__MODULE__.Area{x: x} -> x end) |> Enum.min()

    right =
      areas
      |> Enum.map(fn %__MODULE__.Area{x: x, width: w} -> x + w - 1 end)
      |> Enum.max()

    top = Enum.map(areas, fn %__MODULE__.Area{y: y} -> y end) |> Enum.min()

    bottom =
      areas
      |> Enum.map(fn %__MODULE__.Area{y: y, height: h} -> y + h - 1 end)
      |> Enum.max()

    %__MODULE__.Area{x: left, y: top, width: right - left + 1, height: bottom - top + 1}
  end
end
