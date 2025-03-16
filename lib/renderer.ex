defmodule Orange.Renderer do
  @moduledoc false

  require Logger

  alias Orange.Layout
  alias Orange.Layout.{OutputTreeNode, InputTreeNode}
  alias Orange.Renderer.{Buffer, InputTree}

  @type window :: %{width: integer, height: integer}
  @type ui_element :: Orange.Rect.t()

  # Render the elements to a buffer before painting them to the screen
  # A buffer is a m×n matrix of cells
  @spec render(ui_element, window) :: {Buffer.t(), %{any() => OutputTreeNode.t()}}
  def render(tree, window) do
    start = System.monotonic_time(:millisecond)

    input_tree = InputTree.to_input_tree(tree)
    binding_input_tree_time = System.monotonic_time(:millisecond)

    width = window[:width]
    height = window[:height]
    buffer = Buffer.new({width, height})

    input_tree_lookup_index = build_input_tree_index(input_tree)

    # The tree can be nil if the root element is a fixed position node
    {buffer, output_tree} =
      if input_tree do
        output_tree =
          input_tree
          |> Layout.layout({{:fixed, width}, {:fixed, height}})
          |> Layout.caculate_absolute_position()

        {
          render_node(output_tree, input_tree_lookup_index, buffer, window),
          output_tree
        }
      else
        {buffer, nil}
      end

    now = System.monotonic_time(:millisecond)

    Logger.debug("""
    Renderer took #{now - start}ms:
    - to_input_tree: #{binding_input_tree_time - start}ms
    - render: #{now - binding_input_tree_time}ms
    """)

    out_of_flow_output_tree_index = Process.get(:out_of_flow_output_tree_index, %{})

    {buffer,
     build_output_tree_index(output_tree, input_tree_lookup_index)
     |> Map.merge(out_of_flow_output_tree_index)}
  end

  defp build_input_tree_index(_, result \\ %{})

  defp build_input_tree_index(nil, result), do: result
  defp build_input_tree_index({:fixed, _, _}, result), do: result

  defp build_input_tree_index(%InputTreeNode{} = input_tree, result) do
    result =
      Map.put(
        result,
        input_tree.id,
        Map.take(input_tree, [:id, :style, :out_of_flow_children, :attributes])
      )

    case input_tree.children do
      {:nodes, nodes} -> Enum.reduce(nodes, result, &build_input_tree_index/2)
      {:text, _} -> result
    end
  end

  defp render_node(
         %OutputTreeNode{} = node,
         input_tree_lookup_index,
         buffer,
         window \\ nil
       ) do
    attributes = get_in(input_tree_lookup_index, [node.id, :attributes])

    buffer
    |> render_border(node, attributes)
    |> maybe_render_title(node, attributes[:title])
    |> render_children(node, input_tree_lookup_index, window)
    |> maybe_render_footer(node, attributes[:footer])
    |> maybe_set_background_color(node, attributes)
  end

  defp render_border(
         buffer,
         %OutputTreeNode{border: border, abs_x: x, abs_y: y, width: w, height: h},
         attributes
       ) do
    %{top: top, right: right, bottom: bottom, left: left} = border

    border_color = get_in(attributes, [:style, :border_color])
    border_style = get_in(attributes, [:style, :border_style]) || :default

    {top_left_corner, top_right_corner, bottom_left_corner, bottom_right_corner, horizontal,
     vertical} =
      case border_style do
        :default -> {"┌", "┐", "└", "┘", "─", "│"}
        :dashed -> {"┌", "┐", "└", "┘", "┄", "┆"}
        :round_corners -> {"╭", "╮", "╰", "╯", "─", "│"}
        :double -> {"╔", "╗", "╚", "╝", "═", "║"}
      end

    # Top border
    buffer =
      if top > 0 do
        top_border =
          if(left > 0, do: top_left_corner, else: horizontal) <>
            String.duplicate(horizontal, w - 2) <>
            if(right > 0, do: top_right_corner, else: horizontal)

        Buffer.write_string(buffer, {x, y}, top_border, :horizontal, color: border_color)
      else
        buffer
      end

    # Bottom border
    buffer =
      if bottom > 0 do
        bottom_border =
          if(left > 0, do: bottom_left_corner, else: horizontal) <>
            String.duplicate(horizontal, w - 2) <>
            if(right > 0, do: bottom_right_corner, else: horizontal)

        Buffer.write_string(buffer, {x, y + h - 1}, bottom_border, :horizontal,
          color: border_color
        )
      else
        buffer
      end

    # Left and right border
    start = if top > 0, do: y + 1, else: y
    stop = if bottom > 0, do: y + h - 2, else: y + h - 1
    length = stop - start + 1
    vertical_border = String.duplicate(vertical, length)

    buffer =
      if left > 0 do
        Buffer.write_string(buffer, {x, start}, vertical_border, :vertical, color: border_color)
      else
        buffer
      end

    buffer =
      if right > 0 do
        Buffer.write_string(buffer, {x + w - 1, start}, vertical_border, :vertical,
          color: border_color
        )
      else
        buffer
      end

    buffer
  end

  defp maybe_render_title(buffer, _, nil), do: buffer

  defp maybe_render_title(buffer, node, title) when is_binary(title),
    do: maybe_render_title(buffer, node, %{text: title, offset: 0, align: :left})

  defp maybe_render_title(
         buffer,
         %OutputTreeNode{abs_x: x, abs_y: y, width: w},
         %{
           text: title
         } = title_opts
       )
       when is_binary(title) do
    offset = Map.get(title_opts, :offset, 0)
    align = Map.get(title_opts, :align, :left)

    position_x =
      case align do
        :left -> x + offset + 1
        :right -> x + w - String.length(title) - offset - 1
        :center -> x + div(w - String.length(title), 2) + offset
      end

    Buffer.write_string(buffer, {position_x, y}, title, :horizontal)
  end

  defp maybe_render_title(buffer, node, title) when is_struct(title, Orange.Rect),
    do: maybe_render_title(buffer, node, %{text: title, offset: 0, align: :left})

  defp maybe_render_title(buffer, node, %{text: title} = title_opts)
       when is_struct(title, Orange.Rect) do
    input_tree = InputTree.to_input_tree(title)

    output_tree =
      input_tree
      |> Orange.Layout.layout({{:fixed, node.width}, {:fixed, 1}})

    offset = Map.get(title_opts, :offset, 0)
    align = Map.get(title_opts, :align, :left)

    position_x =
      case align do
        :left -> node.abs_x + offset + 1
        :right -> node.abs_x + node.width - output_tree.width - offset - 1
        :center -> node.abs_x + div(node.width - output_tree.width, 2) + offset
      end

    area = %__MODULE__.Area{
      x: position_x,
      y: node.abs_y,
      width: output_tree.width,
      height: output_tree.height
    }

    buffer = Buffer.clear_area(buffer, area)
    output_tree = Layout.caculate_absolute_position(output_tree, {area.x, area.y})
    input_tree_lookup_index = build_input_tree_index(input_tree)
    render_node(output_tree, input_tree_lookup_index, buffer)
  end

  defp maybe_render_footer(buffer, _, nil), do: buffer

  defp maybe_render_footer(buffer, node, footer) when is_binary(footer),
    do: maybe_render_footer(buffer, node, %{text: footer, offset: 0, align: :right})

  defp maybe_render_footer(
         buffer,
         %OutputTreeNode{abs_x: x, abs_y: y, width: w, height: h},
         %{
           text: footer
         } = footer_opts
       )
       when is_binary(footer) do
    offset = Map.get(footer_opts, :offset, 0)
    align = Map.get(footer_opts, :align, :right)

    position_x =
      case align do
        :left -> x + offset + 1
        :right -> x + w - String.length(footer) - offset - 1
        :center -> x + div(w - String.length(footer), 2) + offset
      end

    Buffer.write_string(buffer, {position_x, y + h - 1}, footer, :horizontal)
  end

  defp maybe_render_footer(buffer, node, footer) when is_struct(footer, Orange.Rect),
    do: maybe_render_footer(buffer, node, %{text: footer, offset: 0, align: :right})

  defp maybe_render_footer(buffer, node, %{text: footer} = footer_opts)
       when is_struct(footer, Orange.Rect) do
    input_tree = InputTree.to_input_tree(footer)

    output_tree =
      input_tree
      |> Orange.Layout.layout({{:fixed, node.width}, {:fixed, 1}})

    offset = Map.get(footer_opts, :offset, 0)
    align = Map.get(footer_opts, :align, :right)

    position_x =
      case align do
        :left -> node.abs_x + offset + 1
        :right -> node.abs_x + node.width - output_tree.width - offset - 1
        :center -> node.abs_x + div(node.width - output_tree.width, 2) + offset
      end

    area = %__MODULE__.Area{
      x: position_x,
      y: node.abs_y + node.height - 1,
      width: output_tree.width,
      height: output_tree.height
    }

    buffer = Buffer.clear_area(buffer, area)
    output_tree = Layout.caculate_absolute_position(output_tree, {area.x, area.y})
    input_tree_lookup_index = build_input_tree_index(input_tree)
    render_node(output_tree, input_tree_lookup_index, buffer)
  end

  defp maybe_set_background_color(
         buffer,
         %OutputTreeNode{
           abs_x: x,
           abs_y: y,
           width: w,
           height: h
         },
         attributes
       ) do
    background_color = get_in(attributes, [:style, :background_color])

    if background_color do
      area =
        %__MODULE__.Area{x: x, y: y, width: w, height: h}

      Buffer.set_background_color(
        buffer,
        area,
        background_color
      )
    else
      buffer
    end
  end

  defp render_children(buffer, node, input_tree_lookup_index, window) do
    attributes = get_in(input_tree_lookup_index, [node.id, :attributes])

    scroll_x = attributes[:scroll_x]
    scroll_y = attributes[:scroll_y]

    if scroll_x || scroll_y,
      do: render_scrollable_children(buffer, node, input_tree_lookup_index),
      else: do_render_children(buffer, node, input_tree_lookup_index, window)
  end

  defp do_render_children(buffer, node, input_tree_lookup_index, window \\ nil) do
    attributes = get_in(input_tree_lookup_index, [node.id, :attributes])

    buffer =
      if background_text = attributes[:background_text],
        do: render_background_text(buffer, node, background_text),
        else: buffer

    buffer =
      case node.children do
        {:text, _text} ->
          start_x = node.abs_x + if(node.border.left > 0, do: 1, else: 0) + node.padding.left
          start_y = node.abs_y + if(node.border.top > 0, do: 1, else: 0) + node.padding.top

          opts = [
            color: get_in(attributes, [:style, :color]),
            text_modifiers: get_in(attributes, [:style, :text_modifiers]) || []
          ]

          # If the first line is all whitespaces or empty, merge it with the second line
          lines = format_lines(node.content_text_lines)

          {buffer, _} =
            Enum.reduce(lines, {buffer, 0}, fn line, {acc_buffer, index} ->
              updated_buffer =
                Buffer.write_string(
                  acc_buffer,
                  {start_x, start_y + index},
                  line,
                  :horizontal,
                  opts
                )

              {updated_buffer, index + 1}
            end)

          buffer

        {:nodes, nodes} ->
          Enum.reduce(nodes, buffer, fn node, buffer ->
            render_node(node, input_tree_lookup_index, buffer, window)
          end)
      end

    # Render the out of flow children after normal chilren
    # The out of flow children have higher z-index
    out_of_flow_children = get_in(input_tree_lookup_index, [node.id, :out_of_flow_children])

    Enum.reduce(out_of_flow_children, buffer, fn
      {:fixed, node, parent_id}, acc ->
        parent_style = get_in(input_tree_lookup_index, [parent_id, :attributes, :style])

        render_out_of_flow_node(
          node,
          acc,
          parent_style,
          {window[:width], window[:height]},
          {0, 0}
        )

      {:absolute, out_of_flow_node, parent_id}, acc ->
        parent_style = get_in(input_tree_lookup_index, [parent_id, :attributes, :style])
        parent_node = node

        render_out_of_flow_node(
          out_of_flow_node,
          acc,
          parent_style,
          {parent_node.width, parent_node.height},
          {parent_node.abs_x, parent_node.abs_y}
        )
    end)
  end

  defp render_background_text(buffer, node, background_text) do
    start_x = node.abs_x + if(node.border.left > 0, do: 1, else: 0) + node.padding.left
    start_y = node.abs_y + if(node.border.top > 0, do: 1, else: 0) + node.padding.top

    inner_width =
      node.width - node.border.left - node.border.right - node.padding.left -
        node.padding.right

    inner_height =
      node.height - node.border.top - node.border.bottom - node.padding.top -
        node.padding.bottom

    if inner_width > 0 and inner_height > 0 do
      {render_text, render_opts} =
        case background_text do
          text when is_binary(text) ->
            {text, []}

          text when is_map(text) ->
            opts =
              text
              |> Map.take([:color, :text_modifiers])
              |> Map.to_list()

            {text[:text], opts}
        end

      Enum.reduce(0..(inner_height - 1), buffer, fn y_offset, acc ->
        background_line =
          String.duplicate(
            render_text,
            ceil(inner_width / String.length(render_text))
          )

        background_line = String.slice(background_line, 0, inner_width)

        Buffer.write_string(
          acc,
          {start_x, start_y + y_offset},
          background_line,
          :horizontal,
          render_opts
        )
      end)
    else
      buffer
    end
  end

  # 1. If the first line is all whitespaces or empty, merge it with the second line
  # 2. Trim trailing whitespaces except for the last line
  defp format_lines([]), do: []

  defp format_lines(lines) do
    total = length(lines)
    first_line = hd(lines)

    lines =
      if String.match?(first_line, ~r/^\s*$/) and total >= 2 do
        merged = first_line <> Enum.at(lines, 1)
        [merged | Enum.slice(lines, 2, total - 2)]
      else
        lines
      end

    # Remove all trailing whitespaces, except for the last line
    last_line = length(lines) - 1

    lines
    |> Enum.with_index()
    |> Enum.map(fn
      {line, ^last_line} -> line
      {line, _} -> String.trim_trailing(line, " ")
    end)
  end

  # The render algorithm is as follows:
  # 1. First render the scrollable children into a separate buffer with dynamic size.
  # 2. Extract the visible area from the children buffer. This area is determined by the scroll offset (x, y) and
  # the width and height of the parent node
  # 3. Merge the visible area into the parent buffer
  defp render_scrollable_children(buffer, node, input_tree_lookup_index) do
    scroll_buffer =
      do_render_children(
        Buffer.new(),
        # Reset the parent container origin to zero
        Layout.caculate_absolute_position(%{node | x: 0, y: 0}),
        input_tree_lookup_index
      )

    node = %{node | content_size: Buffer.size(scroll_buffer)}

    attributes = get_in(input_tree_lookup_index, [node.id, :attributes])

    merge_scrollable_children(
      buffer,
      scroll_buffer,
      node,
      {attributes[:scroll_x], attributes[:scroll_y]},
      attributes[:style]
    )
  end

  defp merge_scrollable_children(
         buffer,
         scrollable_buffer,
         node,
         {scroll_x, scroll_y},
         style
       ) do
    inner_width = node.width - node.border.left - node.border.right
    inner_height = node.height - node.border.top - node.border.bottom

    if inner_width == 0 or inner_height == 0 do
      buffer
    else
      # The scrollbar color should match the border color
      scroll_bar_color = style[:border_color]
      scroll_bar_visibility = Keyword.get(style, :scroll_bar, :visible)

      buffer =
        if scroll_x && scroll_bar_visibility == :visible,
          do: render_horizontal_scroll_bar(buffer, node, scroll_x, scroll_bar_color),
          else: buffer

      buffer =
        if scroll_y && scroll_bar_visibility == :visible,
          do: render_vertical_scroll_bar(buffer, node, scroll_y, scroll_bar_color),
          else: buffer

      scroll_x_offset = scroll_x || 0
      scroll_y_offset = scroll_y || 0

      inner_content_offset_x = node.border.left
      inner_content_offset_y = node.border.top

      # Iterate through the visible area of the scrollable buffer
      Enum.reduce(
        inner_content_offset_y..(inner_content_offset_y + inner_height - 1),
        buffer,
        fn column, acc_buffer ->
          scroll_cell_column = scroll_y_offset + column

          Enum.reduce(
            inner_content_offset_x..(inner_content_offset_x + inner_width - 1),
            acc_buffer,
            fn row, acc_buffer ->
              scroll_cell_row = scroll_x_offset + row

              cell = Buffer.get_cell(scrollable_buffer, {scroll_cell_row, scroll_cell_column})

              if cell != :undefined do
                {buffer_width, buffer_height} = buffer.size
                x = node.abs_x + row
                y = node.abs_y + column

                cond do
                  x >= buffer_width -> acc_buffer
                  y >= buffer_height -> acc_buffer
                  true -> Buffer.write_cell(acc_buffer, {x, y}, cell)
                end
              else
                acc_buffer
              end
            end
          )
        end
      )
    end
  end

  # We need 4 things:
  # 1. What is the total size of the scrollable area
  # 2. What is the size that we can render on the screen
  # 3. What is the scroll offset
  # 4. What is the size of the scroll track
  # The ratio between 1 and 2 determines how big the scroll thumb is
  # The offset 3 determines the offset of the scroll thumb
  defp render_horizontal_scroll_bar(buffer, node, scroll_offset, scroll_bar_color) do
    {content_width, _content_height} = node.content_size

    total_scroll_width = content_width - node.border.left - node.border.right
    renderable_width = node.width - node.border.left - node.border.right

    scroll_track_length = renderable_width
    # It's possible for the renderable_width to be greater than the total_scroll_width
    # It means the content is not overflow. In this case, the scrollable area should
    # be as big as the renderable width.
    total_scroll_width = max(total_scroll_width, renderable_width)

    if total_scroll_width != 0 do
      scroll_thumb_size = round(renderable_width / total_scroll_width * scroll_track_length)

      # Ignore if over scroll
      total_scrolled = min(scroll_offset + renderable_width, total_scroll_width)

      # Important variant that we need to preserve here:
      # a. When the scroll_offset is 0, the scroll thumb MUST be at the top of the track
      # b. When the scroll_offset is maximum (we can no longer scroll down), the scroll thumb MUST
      # be at the bottom of the track
      scroll_thumb_end = round(total_scrolled / total_scroll_width * scroll_track_length)
      scroll_thumb_start = scroll_thumb_end - scroll_thumb_size

      string =
        [
          List.duplicate("─", scroll_thumb_start),
          List.duplicate("🭹", scroll_thumb_size),
          List.duplicate("─", scroll_track_length - scroll_thumb_end),
        ]
        |> IO.iodata_to_binary()

      x = node.abs_x + node.border.left
      y = node.abs_y + node.height - 1
      Buffer.write_string(buffer, {x, y}, string, :horizontal, color: scroll_bar_color)
    else
      buffer
    end
  end

  # Mirror of render_horizontal_scroll_bar
  defp render_vertical_scroll_bar(buffer, node, scroll_offset, scroll_bar_color) do
    {_content_width, content_height} = node.content_size

    total_scroll_height = content_height - node.border.top - node.border.bottom
    renderable_height = node.height - node.border.top - node.border.bottom

    scroll_track_length = renderable_height
    total_scroll_height = max(total_scroll_height, renderable_height)

    if total_scroll_height != 0 do
      scroll_thumb_size = round(renderable_height / total_scroll_height * scroll_track_length)

      # Ignore if over scroll
      total_scrolled = min(scroll_offset + renderable_height, total_scroll_height)

      scroll_thumb_end = round(total_scrolled / total_scroll_height * scroll_track_length)
      scroll_thumb_start = scroll_thumb_end - scroll_thumb_size

      string =
        [
          List.duplicate("│", scroll_thumb_start),
          List.duplicate("▐", scroll_thumb_size),
          List.duplicate("│", scroll_track_length - scroll_thumb_end),
        ]
        |> IO.iodata_to_binary()

      x = node.abs_x + node.width - 1
      y = node.abs_y + node.border.top
      Buffer.write_string(buffer, {x, y}, string, :vertical, color: scroll_bar_color)
    else
      buffer
    end
  end

  # Out-of-flow node render algorithm:
  # 1. In the first render pass, all out-of-flow elements will be collected and removed from the tree
  # 2. After the first pass, render each according to the order of appearance
  #
  # The out-of-flow node still needs to inherit the parent style
  defp render_out_of_flow_node(
         %Orange.Rect{} = rect,
         buffer,
         parent_style,
         {parent_width, parent_height},
         {origin_x, origin_y}
       ) do
    {_, top, right, bottom, left} = rect.attributes[:position]

    rect = %{rect | attributes: Keyword.delete(rect.attributes, :position)}

    style =
      rect.attributes
      |> Keyword.get(:style, [])
      |> Keyword.put_new(:width, "100%")
      |> Keyword.put_new(:height, "100%")

    rect = %{rect | attributes: Keyword.put(rect.attributes, :style, style)}

    input_tree = InputTree.to_input_tree(rect, :atomics.new(1, []), parent_style)

    width =
      cond do
        left != nil and right != nil ->
          # It's possible that the left/right makes the width negative
          width = max(0, parent_width - left - right)
          {:fixed, width}

        left == nil or right == nil ->
          :max_content
      end

    height =
      cond do
        top != nil and bottom != nil ->
          # It's possible that the top/bottom makes the height negative
          height = max(0, parent_height - top - bottom)
          {:fixed, height}

        top == nil or bottom == nil ->
          :max_content
      end

    output_tree = Orange.Layout.layout(input_tree, {width, height})

    # The out-of-flow now will overshadow the layer behind it
    # So we need to clear the render area first
    left = if left, do: left, else: parent_width - right - output_tree.width
    top = if top, do: top, else: parent_height - bottom - output_tree.height

    area = %__MODULE__.Area{
      x: origin_x + left,
      y: origin_y + top,
      width: output_tree.width,
      height: output_tree.height
    }

    buffer = Buffer.clear_area(buffer, area)

    output_tree = Layout.caculate_absolute_position(output_tree, {area.x, area.y})
    input_tree_lookup_index = build_input_tree_index(input_tree)

    # HACK: to avoid passing the output tree indexes of out of flow nodes through functions,
    # we store them in the process dictionary.
    # They will later be merged with the main output tree index.
    output_tree_index = build_output_tree_index(output_tree, input_tree_lookup_index)
    current = Process.get(:out_of_flow_output_tree_index, %{})
    Process.put(:out_of_flow_output_tree_index, Map.merge(current, output_tree_index))

    render_node(output_tree, input_tree_lookup_index, buffer)
  end

  defp build_output_tree_index(_, _, result \\ %{})

  # Build a look up table for the output tree nodes
  # Only include the nodes that have a id attribute
  defp build_output_tree_index(%OutputTreeNode{} = node, input_tree_lookup_index, result) do
    id = get_in(input_tree_lookup_index, [node.id, :attributes, :id])
    result = if id, do: Map.put(result, id, %{node | children: nil}), else: result

    case node.children do
      {:text, _text} ->
        result

      {:nodes, nodes} ->
        Enum.reduce(nodes, result, fn child_node, acc ->
          build_output_tree_index(child_node, input_tree_lookup_index, acc)
        end)
    end
  end

  defp build_output_tree_index(nil, _, _), do: %{}
end
