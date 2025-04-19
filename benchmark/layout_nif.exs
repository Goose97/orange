defmodule Orange.Benchmark.LayoutNif do
  def print_span_duration(span) do
    duration = span.end_time - span.start_time
    IO.puts("Name: #{span.name} - Span duration: #{duration / 1000}micros")
    Enum.each(span.children, &print_span_duration/1)
  end
end

{_, input_tree} = File.read!("./log/orange_input_tree.term") |> :erlang.binary_to_term()

start_time = System.os_time(:nanosecond)
result = Orange.Layout.Binding.layout(input_tree, {{:fixed, 100}, {:fixed, 100}})
end_time = System.os_time(:nanosecond)

Orange.Benchmark.LayoutNif.print_span_duration(result.spans)

start_overhead = result.spans.start_time - start_time
end_overhead = end_time - result.spans.end_time
IO.puts("NIF start overhead: #{start_overhead / 1000}micros")
IO.puts("NIF end overhead: #{end_overhead / 1000}micros")
IO.puts("Total: #{(end_time - start_time) / 1000}micros")
