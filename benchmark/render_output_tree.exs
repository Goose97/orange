{output_tree, input_tree_lookup_index, buffer, window} =
  :erlang.binary_to_term(File.read!("./benchmark/orange_render_output_tree.term"))

raw_text = %Orange.RawText{direction: :row, content: [%{text: "hello"}]}

Benchee.run(
  %{
    "old" => fn ->
      Orange.Renderer.render_raw_text(buffer, output_tree, raw_text)
    end
  },
  time: 10,
  memory_time: 2,
  warmup: 2
)
