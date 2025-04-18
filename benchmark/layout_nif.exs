require Logger
input_tree = File.read!("./log/orange_input_tree.term") |> :erlang.binary_to_term()
result = Orange.Layout.Binding.layout(input_tree, {{:fixed, 100}, {:fixed, 100}})
IO.inspect(result)
