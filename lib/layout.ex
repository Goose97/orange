defmodule Orange.Layout do
  @moduledoc false

  require OpenTelemetry.Tracer, as: Tracer

  alias __MODULE__.OutputTreeNode

  def layout(tree, window_size) do
    output_tree =
      Tracer.with_span "layout_binding" do
        %{root: output_tree, spans: span} = __MODULE__.Binding.layout(tree, window_size)
        create_spans(span)
        output_tree
      end

    Tracer.with_span "layout_rounding" do
      perform_rounding(output_tree)
    end
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

    new_width = round(acc_x + node.width * scale_x) - round(acc_x)
    new_height = round(acc_y + node.height * scale_y) - round(acc_y)

    updated_node =
      Map.merge(node, %{
        x: round(node.x),
        y: round(node.y),
        width: new_width,
        height: new_height
      })

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

          # Adjust the acc to account for the difference after rounding
          acc_x = acc_x + (updated_node.x - node.x)
          acc_y = acc_y + (updated_node.y - node.y)
          rounded = Enum.map(nodes, &perform_rounding(&1, {acc_x, acc_y}, {scale_x, scale_y}))

          {:nodes, rounded}
      end

    %{updated_node | children: children}
  end

  def caculate_absolute_position(%OutputTreeNode{} = node, {acc_x, acc_y} \\ {0, 0}) do
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

  # Recursively creates OpenTelemetry spans from NIF-generated spans
  defp create_spans(%__MODULE__.Span{} = span) do
    old_ctx = Tracer.current_span_ctx()

    span_ctx =
      Tracer.start_span(span.name, start_time: span.start_time - System.time_offset(:nanosecond))

    Tracer.set_current_span(span_ctx)
    Enum.each(span.children, &create_spans/1)
    Tracer.end_span(span.end_time - System.time_offset(:nanosecond))
    Tracer.set_current_span(old_ctx)
  end

  defmodule Binding do
    @moduledoc false

    use RustlerPrecompiled,
      otp_app: :orange,
      crate: "orange_layout_binding",
      base_url: "https://github.com/Goose97/orange/releases/download/v0.5.0",
      version: "0.5.0",
      targets: [
        "arm-unknown-linux-gnueabihf",
        "aarch64-unknown-linux-gnu",
        "aarch64-unknown-linux-musl",
        "aarch64-apple-darwin",
        "riscv64gc-unknown-linux-gnu",
        "x86_64-apple-darwin",
        "x86_64-unknown-linux-gnu",
        "x86_64-unknown-linux-musl",
        "x86_64-pc-windows-gnu",
        "x86_64-pc-windows-msvc"
      ],
      nif_versions: ["2.15", "2.16"]

    def layout(_tree, _window_size), do: :erlang.nif_error(:nif_not_loaded)
  end
end
