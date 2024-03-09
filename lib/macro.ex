defmodule Orange.Macro do
  defmacro rect(attrs \\ [], do_block) do
    children = get_children(do_block)

    quote do
      children =
        unquote(children)
        |> Enum.reject(&is_nil/1)
        |> Orange.Macro.normalize_children(:rect)

      Orange.Macro.validate_children!(children, :rect)

      %Orange.Rect{
        children: children,
        attributes: unquote(attrs)
      }
    end
  end

  defmacro line(attrs \\ [], do_block) do
    children = get_children(do_block)

    quote do
      children =
        unquote(children)
        |> Enum.reject(&is_nil/1)
        |> Orange.Macro.normalize_children(:line)

      Orange.Macro.validate_children!(children, :line)

      %Orange.Line{
        children: children,
        attributes: unquote(attrs)
      }
    end
  end

  defmacro span(attrs \\ [], do_block) do
    children = get_children(do_block)

    quote do
      Orange.Macro.validate_children!(unquote(children), :span)

      %Orange.Span{
        children: unquote(children),
        attributes: unquote(attrs)
      }
    end
  end

  def normalize_children(children, :rect) when is_list(children) do
    for child <- List.flatten(children) do
      case child do
        text when is_binary(text) ->
          span = %Orange.Span{children: [text]}

          %Orange.Line{children: [span]}

        span when is_struct(span, Orange.Span) ->
          %Orange.Line{children: [span]}

        custom when is_atom(custom) ->
          %Orange.CustomComponent{module: custom, attributes: []}

        {custom, attrs} when is_atom(custom) ->
          %Orange.CustomComponent{module: custom, attributes: attrs}

        other ->
          other
      end
    end
  end

  def normalize_children(children, :line) when is_list(children) do
    for child <- List.flatten(children) do
      case child do
        text when is_binary(text) ->
          %Orange.Span{children: [text]}

        other ->
          other
      end
    end
  end

  defp get_children(do_block) do
    case do_block[:do] do
      {:__block__, _, children} -> children
      child -> [child]
    end
    |> Enum.map(&Macro.expand(&1, __ENV__))
  end

  def validate_children!(children, :rect) do
    for child <- children do
      case child do
        %Orange.Rect{} ->
          :ok

        %Orange.Line{} ->
          :ok

        %Orange.CustomComponent{} ->
          :ok

        _ ->
          raise "#{__MODULE__}: Invalid rect child. Expected a rect or line, instead got: #{inspect(child, pretty: true)}"
      end
    end
  end

  def validate_children!(children, :line) do
    for child <- children do
      case child do
        %Orange.Span{} ->
          :ok

        _ ->
          raise "#{__MODULE__}: Invalid line child. Expected a span, instead got: #{inspect(child, pretty: true)}"
      end
    end
  end

  def validate_children!(children, :span) do
    case children do
      [text] when is_binary(text) ->
        :ok

      _ ->
        raise "#{__MODULE__}: Invalid span children. Expected a single text child, instead got #{inspect(children, pretty: true)}"
    end
  end
end
