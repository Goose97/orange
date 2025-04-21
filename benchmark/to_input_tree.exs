component_tree = :erlang.binary_to_term(File.read!("./benchmark/orange_component_tree.term"))

Benchee.run(
  %{
    "old" => fn -> Orange.Renderer.InputTree.to_input_tree(component_tree) end
  },
  time: 10,
  memory_time: 2,
  warmup: 2
)
