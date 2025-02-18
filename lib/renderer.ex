defmodule Orange.Renderer do
  @moduledoc false

  alias Orange.Renderer.Buffer
  alias Orange.Layout.{OutputTreeNode, InputTreeNode}

  @type window :: %{width: integer, height: integer}
  @type style_chain :: [Keyword.t()]
  @type ui_element :: Orange.Rect.t()

  # Render the elements to a buffer before painting them to the screen
  # A buffer is a m×n matrix of cells
  @spec render(ui_element, window) :: {Buffer.t(), %{any() => OutputTreeNode.t()}}
  def render(tree, window) do
    {tree, node_attributes_map, out_of_flow_nodes} = to_binding_input_tree(tree)

    width = window[:width]
    height = window[:height]
    buffer = Buffer.new({width, height})

    # The tree can be nil if the root element is a fixed position node
    {buffer, output_tree} =
      if tree do
        output_tree =
          tree
          |> Orange.Layout.layout({{:fixed, width}, {:fixed, height}})
          |> perform_rounding()
          |> caculate_absolute_position()

        {render_node(output_tree, buffer, node_attributes_map, []), output_tree}
      else
        {buffer, nil}
      end

    buffer =
      Enum.reduce(out_of_flow_nodes, buffer, fn
        {:fixed, node}, acc ->
          render_fixed(node, acc, window)

        {:absolute, node, parent_id}, acc ->
          # TODO: only fetch the node that needs for the absolute render instead of the whole tree
          output_tree_map = build_output_tree_map(output_tree)
          render_absolute(node, acc, parent_id, output_tree_map)
      end)

    {buffer, build_output_tree_id_map(output_tree, node_attributes_map)}
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
          scale_x = if node.width == 0, do: 1, else: new_width / node.width
          scale_y = if node.height == 0, do: 1, else: new_height / node.height
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

  defp render_node(
         %OutputTreeNode{} = node,
         buffer,
         node_attributes_map,
         style_chain
       ) do
    attributes = Map.get(node_attributes_map, node.id, [])

    buffer
    |> render_border(node, attributes)
    |> maybe_render_title(node, attributes[:title])
    |> render_children(node, node_attributes_map, style_chain)
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

  # In case the title is a list, the item will be rendered one after another
  defp maybe_render_title(buffer, node, title) when is_list(title) do
    normalized =
      Enum.map(title, fn
        string when is_binary(string) -> %{text: string}
        map when is_map(map) -> map
      end)

    # Add offset to each title
    {normalized, _} =
      Enum.flat_map_reduce(normalized, 0, fn item, acc ->
        updated = Map.put(item, :offset, acc)
        {[updated], acc + String.length(item.text)}
      end)

    Enum.reduce(normalized, buffer, fn title, acc ->
      maybe_render_title(acc, node, title)
    end)
  end

  defp maybe_render_title(buffer, %OutputTreeNode{abs_x: x, abs_y: y}, title) do
    {title_text, offset, opts} =
      case title do
        title when is_binary(title) ->
          {title, 0, []}

        title when is_map(title) ->
          opts =
            title
            |> Map.take([:color, :text_modifiers])
            |> Map.to_list()

          {title[:text], Map.get(title, :offset, 0), opts}
      end

    Buffer.write_string(
      buffer,
      {x + offset + 1, y},
      title_text,
      :horizontal,
      opts
    )
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

  defp render_children(buffer, node, node_attributes_map, style_chain) do
    attributes = Map.get(node_attributes_map, node.id, [])
    scroll_x = attributes[:scroll_x]
    scroll_y = attributes[:scroll_y]

    if scroll_x || scroll_y,
      do: render_scrollable_children(buffer, node, node_attributes_map, style_chain),
      else: do_render_children(buffer, node, node_attributes_map, style_chain)
  end

  defp do_render_children(buffer, node, node_attributes_map, style_chain) do
    attributes = Map.get(node_attributes_map, node.id, [])
    style_chain = [Keyword.get(attributes, :style, []) | style_chain]

    buffer =
      if background_text = attributes[:background_text],
        do: render_background_text(buffer, node, background_text),
        else: buffer

    case node.children do
      {:text, _text} ->
        start_x = node.abs_x + if(node.border.left > 0, do: 1, else: 0) + node.padding.left
        start_y = node.abs_y + if(node.border.top > 0, do: 1, else: 0) + node.padding.top

        opts = [
          color: get_style_from_chain(style_chain, :color),
          text_modifiers: get_style_from_chain(style_chain, :text_modifiers) || []
        ]

        # If the first line is all whitespaces or empty, merge it with the second line
        lines = format_lines(node.content_text_lines)

        {buffer, _} =
          Enum.reduce(lines, {buffer, 0}, fn line, {acc_buffer, index} ->
            updated_buffer =
              Buffer.write_string(acc_buffer, {start_x, start_y + index}, line, :horizontal, opts)

            {updated_buffer, index + 1}
          end)

        buffer

      {:nodes, nodes} ->
        Enum.reduce(nodes, buffer, fn node, buffer ->
          render_node(node, buffer, node_attributes_map, style_chain)
        end)
    end
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
  # 1. First render the scrollable children into a separate buffer.
  # 2. Extract the visible area from the children buffer. This area is determined by the scroll offset (x, y) and
  # the width and height of the parent node
  # 3. Merge the visible area into the parent buffer
  defp render_scrollable_children(buffer, node, node_attributes_map, style_chain) do
    scroll_buffer = Buffer.new()

    scroll_buffer =
      do_render_children(
        scroll_buffer,
        # Reset the parent container origin to zero
        caculate_absolute_position(%{node | x: 0, y: 0}),
        node_attributes_map,
        style_chain
      )

    attributes = Map.get(node_attributes_map, node.id, [])

    merge_scrollable_children(
      buffer,
      scroll_buffer,
      node,
      {attributes[:scroll_x], attributes[:scroll_y]}
    )
  end

  defp merge_scrollable_children(buffer, scrollable_buffer, node, {scroll_x, scroll_y}) do
    inner_width =
      node.width - node.padding.left - node.padding.right - node.border.left -
        node.border.right

    inner_height =
      node.height - node.padding.top - node.padding.bottom - node.border.top -
        node.border.bottom

    inner_start_x = (scroll_x || 0) + node.padding.left + node.border.left
    inner_start_y = (scroll_y || 0) + node.padding.top + node.border.top

    children_viewport =
      extract_buffer_viewport(
        scrollable_buffer,
        inner_start_x,
        inner_start_y,
        inner_width,
        inner_height
      )

    offset_x = node.border.left + node.padding.left
    offset_y = node.border.top + node.padding.top

    Enum.with_index(children_viewport)
    |> Enum.reduce(buffer, fn {row, row_index}, acc ->
      Enum.with_index(row)
      |> Enum.reduce(acc, fn {cell, col_index}, acc ->
        if cell != :undefined do
          Buffer.write_cell(
            acc,
            {node.abs_x + offset_x + col_index, node.abs_y + offset_y + row_index},
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

  defp build_output_tree_map(output_tree, map \\ %{}) do
    map = Map.put(map, output_tree.id, Map.delete(output_tree, :children))

    case output_tree.children do
      {:nodes, nodes} ->
        Enum.reduce(nodes, map, fn node, acc ->
          build_output_tree_map(node, acc)
        end)

      {:text, _text} ->
        map
    end
  end

  # Fixed position render algorithm:
  # 1. In the first render pass, all fixed position boxes will be collected and removed from the tree
  # 2. After the first pass, render each fixed position box, according to the order of appearance
  defp render_absolute(
         %Orange.Rect{} = rect,
         buffer,
         parent_id,
         output_tree_map
       ) do
    # Absolute layer will overshadow the layer behind it
    {:absolute, top, right, bottom, left} = rect.attributes[:position]

    # Render as non-absolute position node
    rect = %{rect | attributes: Keyword.delete(rect.attributes, :position)}

    # If width/height is not specified, use 100% as default
    style =
      rect.attributes
      |> Keyword.get(:style, [])
      |> Keyword.put_new(:width, "100%")
      |> Keyword.put_new(:height, "100%")

    rect = %{rect | attributes: Keyword.put(rect.attributes, :style, style)}

    {tree, node_attributes_map, _out_of_flow_nodes} = to_binding_input_tree(rect)

    output_parent = Map.get(output_tree_map, parent_id)

    width =
      cond do
        left != nil and right != nil ->
          # It's possible that the left/right makes the width negative
          width = max(0, output_parent.width - left - right)
          {:fixed, width}

        left == nil or right == nil ->
          :max_content
      end

    height =
      cond do
        top != nil and bottom != nil ->
          # It's possible that the top/bottom makes the height negative
          height = max(0, output_parent.height - top - bottom)
          {:fixed, height}

        top == nil or bottom == nil ->
          :max_content
      end

    output_tree =
      tree
      |> Orange.Layout.layout({width, height})
      |> perform_rounding()

    area = absolute_child_render_area({top, right, bottom, left}, output_tree, output_parent)
    buffer = Buffer.clear_area(buffer, area)

    output_tree =
      caculate_absolute_position(output_tree, {area.x, area.y})

    render_node(
      output_tree,
      buffer,
      node_attributes_map,
      []
    )
  end

  defp absolute_child_render_area(
         {top, right, bottom, left},
         %OutputTreeNode{} = output_node,
         %OutputTreeNode{} = output_parent_node
       ) do
    left = if left, do: left, else: output_parent_node.width - right - output_node.width
    top = if top, do: top, else: output_parent_node.height - bottom - output_node.height

    %__MODULE__.Area{
      x: output_parent_node.abs_x + left,
      y: output_parent_node.abs_y + top,
      width: output_node.width,
      height: output_node.height
    }
  end

  defp render_fixed(%Orange.Rect{} = rect, buffer, window) do
    # Fixed layer will overshadow the layer behind it
    {:fixed, top, right, bottom, left} = rect.attributes[:position]

    width =
      cond do
        left != nil and right != nil ->
          # It's possible that the left/right makes the width negative
          width = max(0, window[:width] - left - right)
          {:fixed, width}

        left == nil or right == nil ->
          :max_content
      end

    height =
      cond do
        top != nil and bottom != nil ->
          # It's possible that the top/bottom makes the height negative
          height = max(0, window[:height] - top - bottom)
          {:fixed, height}

        top == nil or bottom == nil ->
          :max_content
      end

    # Render as non-fixed position node
    rect = %{rect | attributes: Keyword.delete(rect.attributes, :position)}

    # If width/height is not specified, use 100% as default
    style =
      rect.attributes
      |> Keyword.get(:style, [])
      |> Keyword.put_new(:width, "100%")
      |> Keyword.put_new(:height, "100%")

    rect = %{rect | attributes: Keyword.put(rect.attributes, :style, style)}

    # If fixed position node has nested fixed position children, ignore them for now
    {tree, node_attributes_map, _out_of_flow_nodes} = to_binding_input_tree(rect)

    output_tree =
      tree
      |> Orange.Layout.layout({width, height})
      |> perform_rounding()

    area = fixed_child_render_area({top, right, bottom, left}, output_tree, window)
    buffer = Buffer.clear_area(buffer, area)

    output_tree = caculate_absolute_position(output_tree, {area.x, area.y})
    render_node(output_tree, buffer, node_attributes_map, [])
  end

  defp fixed_child_render_area(
         {top, right, bottom, left},
         %OutputTreeNode{} = output_node,
         window
       ) do
    left = if left, do: left, else: window[:width] - right - output_node.width
    top = if top, do: top, else: window[:height] - bottom - output_node.height

    %__MODULE__.Area{
      x: left,
      y: top,
      width: output_node.width,
      height: output_node.height
    }
  end

  defp get_style_from_chain(style_chain, attribute),
    do: Enum.find_value(style_chain, &Keyword.get(&1, attribute))

  defp to_binding_input_tree(
         _node,
         counter \\ :atomics.new(1, []),
         node_map \\ %{},
         out_of_flow_nodes \\ [],
         parent_style \\ nil,
         parent_id \\ nil
       )

  # Convert a component tree to a input tree to pass to the layout binding
  # Traverse the tree and convert recursively. During the traversal:
  # 1. Collect node attributes
  # 2. Collect fixed position nodes
  defp to_binding_input_tree(
         %Orange.Rect{} = node,
         counter,
         node_map,
         out_of_flow_nodes,
         _parent_style,
         parent_id
       ) do
    new_id = :atomics.add_get(counter, 1, 1)
    raw_style = node.attributes[:style]
    style = if raw_style, do: to_binding_style(node.attributes[:style])

    # Collect fixed and absolute position nodes
    {new_node, node_map, out_of_flow_nodes} =
      case node.attributes[:position] do
        {:fixed, _, _, _, _} = position ->
          validate_position!(position)
          {nil, node_map, out_of_flow_nodes ++ [{:fixed, node}]}

        {:absolute, _, _, _, _} = position ->
          if !parent_id, do: raise("Absolute position can't be used on root element")
          validate_position!(position)
          {nil, node_map, out_of_flow_nodes ++ [{:absolute, node, parent_id}]}

        _ ->
          {children, updated_node_map, updated_out_of_flow_nodes} =
            Enum.reduce(node.children, {[], node_map, out_of_flow_nodes}, fn node,
                                                                             {result,
                                                                              node_map_acc,
                                                                              out_of_flow_nodes_acc} ->
              {new_node, new_node_map, new_out_of_flow_nodes} =
                to_binding_input_tree(
                  node,
                  counter,
                  node_map_acc,
                  out_of_flow_nodes_acc,
                  raw_style,
                  new_id
                )

              # new_node can be nil if the node is a fixed position node
              result = if new_node, do: result ++ [new_node], else: result
              {result, new_node_map, new_out_of_flow_nodes}
            end)

          {
            %InputTreeNode{
              id: new_id,
              children: {:nodes, children},
              style: style
            },
            updated_node_map,
            updated_out_of_flow_nodes
          }
      end

    # Save node attributes
    node_map = Map.put(node_map, new_id, node.attributes)

    {new_node, node_map, out_of_flow_nodes}
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
  defp to_binding_input_tree(
         string,
         counter,
         node_map,
         out_of_flow_nodes,
         parent_style,
         _parent_id
       ) do
    new_id = :atomics.add_get(counter, 1, 1)

    inherit_style =
      if parent_style,
        do: Keyword.take(parent_style, [:color, :text_modifiers, :line_wrap]),
        else: []

    # Save node attributes
    node_map = Map.put(node_map, new_id, style: inherit_style)

    new_node = %InputTreeNode{
      id: new_id,
      children: {:text, string},
      style: if(inherit_style, do: to_binding_style(inherit_style))
    }

    {new_node, node_map, out_of_flow_nodes}
  end

  defp to_binding_style(style) do
    %InputTreeNode.Style{
      width: parse_length_percentage(style[:width]),
      height: parse_length_percentage(style[:height]),
      border: expand_border(style),
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

  defp build_output_tree_id_map(_, _, result \\ %{})

  # Build a look up table for the output tree nodes
  # Only include the nodes that have a id attribute
  defp build_output_tree_id_map(%OutputTreeNode{} = node, node_attributes_map, result) do
    id = Map.get(node_attributes_map, node.id, []) |> Keyword.get(:id)

    result =
      if id do
        Map.put(result, id, %{node | children: nil})
      else
        result
      end

    case node.children do
      {:text, _text} ->
        result

      {:nodes, nodes} ->
        Enum.reduce(nodes, result, fn child_node, acc ->
          build_output_tree_id_map(child_node, node_attributes_map, acc)
        end)
    end
  end

  defp build_output_tree_id_map(nil, _, _), do: %{}
end
