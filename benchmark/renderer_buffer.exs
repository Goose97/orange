alias Orange.Renderer.{Buffer, TestBuffer}

# ┌─────────────┐
# │-│bar│-------│
# │-└───┘-------│
# │-baz---------│
# └─────────────┘\

Benchee.run(
  %{
    "nested_array" => fn ->
      buffer = Buffer.new({15, 5})

      buffer
      |> Buffer.write_string({3, 1}, "bar", :horizontal)
      |> Buffer.write_string({2, 1}, "│└", :vertical)
      |> Buffer.write_string({6, 1}, "│┘", :vertical)
      |> Buffer.write_string({3, 2}, "───", :horizontal)
      |> Buffer.write_string({2, 3}, "baz", :horizontal)
      |> Buffer.write_string({0, 0}, "┌│││└", :vertical)
      |> Buffer.write_string({14, 0}, "┐│││┘", :vertical)
      |> Buffer.write_string({1, 0}, "─────────────", :horizontal)
      |> Buffer.write_string({1, 4}, "─────────────", :horizontal)
    end
  },
  time: 10,
  memory_time: 2
)
