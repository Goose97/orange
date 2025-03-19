defmodule Orange.Renderer.InputTree do
  alias Orange.Layout.InputTreeNode
  alias Orange.Renderer.Style

  def to_input_tree(
        node,
        counter \\ :atomics.new(1, []),
        parent_style \\ nil,
        parent_id \\ nil
      ) do
    case do_to_input_tree(node, counter, parent_style, parent_id) do
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
  defp do_to_input_tree(
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
        inherited_style = Style.inherit_style(node.attributes[:style], parent_style)

        children =
          for child_node <- node.children do
            do_to_input_tree(child_node, counter, inherited_style, new_id)
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
            Style.to_binding_style(
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
  defp do_to_input_tree(
         string,
         counter,
         parent_style,
         _parent_id
       ) do
    new_id = :atomics.add_get(counter, 1, 1)

    line_wrap = parent_style[:line_wrap]
    style = Style.inherit_style(nil, parent_style)

    style =
      if line_wrap != nil, do: Keyword.put(style || [], :line_wrap, line_wrap), else: style

    if not is_binary(string) do
      raise(
        "#{__MODULE__}.to_input_tree: invalid element children. Expected a string or another element, got #{inspect(string, pretty: true)}"
      )
    end

    new_node = %InputTreeNode{
      id: new_id,
      children: {:text, string},
      style: Style.to_binding_style(style),
      out_of_flow_children: [],
      attributes: [style: style]
    }

    new_node
  end

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
end
