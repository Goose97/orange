defmodule Orange.Renderer do
  @moduledoc false

  require Logger

  alias Orange.Renderer.Buffer
  alias Orange.Layout.{OutputTreeNode, InputTreeNode}

  @type window :: %{width: integer, height: integer}
  @type ui_element :: Orange.Rect.t()

  # Render the elements to a buffer before painting them to the screen
  # A buffer is a m×n matrix of cells
  @spec render(ui_element, window) :: {Buffer.t(), %{any() => OutputTreeNode.t()}}
  def render(tree, window) do
    start = System.monotonic_time(:millisecond)

    input_tree = to_binding_input_tree(tree)
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
          |> Orange.Layout.layout({{:fixed, width}, {:fixed, height}})
          |> perform_rounding()
          |> caculate_absolute_position()

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
    - to_binding_input_tree: #{binding_input_tree_time - start}ms
    - render: #{now - binding_input_tree_time}ms
    """)

    {buffer, build_output_tree_index(output_tree, input_tree_lookup_index)}
  end

  # The layout algorithm returns float values for positions and sizes.
  # We need to round these values to integers so that we can render them to the screen.
  # Adapt from taffy: https://github.com/DioxusLabs/taffy/blob/0386dc966a41b6b10e4089018fcbeada72504df6/src/compute/mod.rs#L205-L260
  defp perform_rounding(
         %OutputTreeNode{} = node,
         {acc_x, acc_y} \\ {0, 0},
         {scale_x, scale_y} \\ {1, 1}
       ) do
    node = %{node | x: node.x * scale_x, y: node.y * scale_y}

    acc_x = acc_x + node.x
    acc_y = acc_y + node.y

    new_width = round(round(acc_x + node.width) - round(acc_x))
    new_height = round(round(acc_y + node.height) - round(acc_y))

    children =
      case node.children do
        {:text, _text} = child ->
          child

        {:nodes, nodes} ->
          # I'm not sure if this is the correct way to perform rounding
          scale_x =
            cond do
              node.width == 0 -> 1
              elem(node.content_size, 0) == 0 -> 1
              elem(node.content_size, 0) == node.width -> new_width / node.width
              true -> 1 + (new_width - node.width) / elem(node.content_size, 0)
            end

          scale_y =
            cond do
              node.height == 0 -> 1
              elem(node.content_size, 1) == 0 -> 1
              elem(node.content_size, 1) == node.height -> new_height / node.height
              true -> 1 + (new_height - node.height) / elem(node.content_size, 1)
            end

          rounded = Enum.map(nodes, &perform_rounding(&1, {acc_x, acc_y}, {scale_x, scale_y}))
          {:nodes, rounded}
      end

    %OutputTreeNode{
      id: node.id,
      x: round(node.x),
      y: round(node.y),
      width: new_width,
      height: new_height,
      border: node.border,
      padding: node.padding,
      margin: node.margin,
      content_text_lines: node.content_text_lines,
      content_size: node.content_size,
      children: children
    }
  end

  defp caculate_absolute_position(%OutputTreeNode{} = node, {acc_x, acc_y} \\ {0, 0}) do
    node_x = acc_x + node.x
    node_y = acc_y + node.y

    children =
      case node.children do
        {:text, _text} = child ->
          child

        {:nodes, nodes} ->
          {:nodes, Enum.map(nodes, &caculate_absolute_position(&1, {node_x, node_y}))}
      end

    Map.merge(node, %{
      abs_x: node_x,
      abs_y: node_y,
      children: children
    })
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
    do: maybe_render_title(buffer, node, %{text: title, offset: 0})

  defp maybe_render_title(buffer, %OutputTreeNode{abs_x: x, abs_y: y}, %{
         text: title,
         offset: offset
       })
       when is_binary(title) do
    Buffer.write_string(buffer, {x + offset + 1, y}, title, :horizontal)
  end

  defp maybe_render_title(buffer, node, title) when is_struct(title, Orange.Rect),
    do: maybe_render_title(buffer, node, %{text: title, offset: 0})

  defp maybe_render_title(buffer, node, %{text: title, offset: offset} = _title)
       when is_struct(title, Orange.Rect) do
    input_tree = to_binding_input_tree(title)

    output_tree =
      input_tree
      |> Orange.Layout.layout({{:fixed, node.width}, {:fixed, 1}})
      |> perform_rounding()

    area = %__MODULE__.Area{
      x: node.abs_x + offset + 1,
      y: node.abs_y,
      width: output_tree.width,
      height: output_tree.height
    }

    buffer = Buffer.clear_area(buffer, area)
    output_tree = caculate_absolute_position(output_tree, {area.x, area.y})
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
        caculate_absolute_position(%{node | x: 0, y: 0}),
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
  end

  # Mirror of render_horizontal_scroll_bar
  defp render_vertical_scroll_bar(buffer, node, scroll_offset, scroll_bar_color) do
    {_content_width, content_height} = node.content_size

    total_scroll_height = content_height - node.border.top - node.border.bottom
    renderable_height = node.height - node.border.top - node.border.bottom

    scroll_track_length = renderable_height
    total_scroll_height = max(total_scroll_height, renderable_height)

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

    input_tree = to_binding_input_tree(rect, :atomics.new(1, []), parent_style)

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

    output_tree =
      input_tree
      |> Orange.Layout.layout({width, height})
      |> perform_rounding()

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

    output_tree = caculate_absolute_position(output_tree, {area.x, area.y})
    render_node(output_tree, build_input_tree_index(input_tree), buffer)
  end

  defp to_binding_input_tree(
         node,
         counter \\ :atomics.new(1, []),
         parent_style \\ nil,
         parent_id \\ nil
       ) do
    case do_to_binding_input_tree(node, counter, parent_style, parent_id) do
      {:fixed, _, _} = fixed ->
        # If the root node is fixed, normalize the output
        new_id = :atomics.add_get(counter, 1, 1)

        %InputTreeNode{
          id: new_id,
          children: {:nodes, []},
          out_of_flow_children: [fixed],
          attributes: [],
          style: nil
        }

      node ->
        node
    end
  end

  # Convert a component tree to a input tree to pass to the layout binding
  # Traverse the tree and convert recursively
  defp do_to_binding_input_tree(
         %Orange.Rect{} = node,
         counter,
         parent_style,
         parent_id
       ) do
    new_id = :atomics.add_get(counter, 1, 1)

    # Process out-of-flow nodes (fixed and absolute position)
    case node.attributes[:position] do
      {:fixed, _, _, _, _} = position ->
        validate_position!(position)
        {:fixed, node, parent_id}

      {:absolute, _, _, _, _} = position ->
        if !parent_id, do: raise("Absolute position can't be used on root element")
        validate_position!(position)
        {:absolute, node, parent_id}

      _ ->
        inherited_style = inherit_style(node.attributes[:style], parent_style)

        children =
          for child_node <- node.children do
            do_to_binding_input_tree(child_node, counter, inherited_style, new_id)
          end

        {normal_children, out_of_flow_children} =
          Enum.split_with(children, fn
            %InputTreeNode{} -> true
            {:fixed, _, _} -> false
            {:absolute, _, _} -> false
          end)

        %InputTreeNode{
          id: new_id,
          children: {:nodes, normal_children},
          out_of_flow_children: out_of_flow_children,
          attributes: Keyword.put(node.attributes, :style, inherited_style),
          style:
            to_binding_style(
              inherited_style,
              node.attributes[:scroll_x],
              node.attributes[:scroll_y]
            )
        }
    end
  end

  # A simple text node, like:
  #
  # rect do
  #   "foo"
  # end
  #
  # will be converted to:
  #
  # %InputTreeNode{
  #   id: 1,
  #   children: {:nodes, [
  #     %InputTreeNode{
  #       id: 1,
  #       children: {:text, "foo"},
  #       style: nil
  #     }
  #   ]},
  #   style: nil
  # }
  #
  # The inner node should inherit the parent style
  defp do_to_binding_input_tree(
         string,
         counter,
         parent_style,
         _parent_id
       ) do
    new_id = :atomics.add_get(counter, 1, 1)

    line_wrap = parent_style[:line_wrap]
    style = inherit_style(nil, parent_style)

    style =
      if line_wrap != nil, do: Keyword.put(style || [], :line_wrap, line_wrap), else: style

    new_node = %InputTreeNode{
      id: new_id,
      children: {:text, string},
      style: to_binding_style(style),
      out_of_flow_children: [],
      attributes: [style: style]
    }

    new_node
  end

  defp inherit_style(style, nil), do: style
  defp inherit_style(nil, parent_style), do: inherit_style([], parent_style)

  defp inherit_style(style, parent_style) do
    parent_color = parent_style[:color]
    parent_text_modifiers = parent_style[:text_modifiers]

    style = if parent_color, do: Keyword.put_new(style, :color, parent_color), else: style

    if parent_text_modifiers,
      do: Keyword.put_new(style, :text_modifiers, parent_text_modifiers),
      else: style
  end

  defp to_binding_style(style, scroll_x \\ nil, scroll_y \\ nil)

  defp to_binding_style(nil, _, _), do: nil

  defp to_binding_style(style, scroll_x, scroll_y) do
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
      grid_row: parse_grid_line_pair(style[:grid_row]),
      grid_column: parse_grid_line_pair(style[:grid_column])
    }
  end

  defp parse_length_percentage(size) do
    cond do
      is_integer(size) ->
        {:fixed, size}

      is_binary(size) and String.ends_with?(size, "%") ->
        {float, "%"} = Float.parse(size)
        {:percent, float / 100}

      size == nil ->
        size
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
      :auto ->
        :auto

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

  defp validate_position!({type, top, right, bottom, left}) when type in [:absolute, :fixed] do
    type_text =
      case type do
        :absolute -> "Absolute"
        :fixed -> "Fixed"
      end

    if !top and !bottom,
      do: raise("#{type_text} position element must specify either top or bottom")

    if !left and !right,
      do: raise("#{type_text} position element must specify either left or right")
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
