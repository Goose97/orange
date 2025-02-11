defmodule Grid.App do
  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: nil, events_subscription: true}

  @impl true
  def handle_event(event, state, _attrs, _update) do
    case event do
      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        Orange.stop()
        state

      _ ->
        state
    end
  end

  @impl true
  def render(_state, _attrs, _update) do
    rect style: [
           width: 20,
           height: 20,
           border: true,
           display: :grid,
           grid_template_rows: [1, 1],
           grid_template_columns: [1, 1]
         ] do
      rect style: [grid_row: {1, 2}, grid_column: {1, 2}, border: true] do
        "foo"
      end

      rect style: [grid_row: {2, 3}, grid_column: {2, 3}, border: true] do
        "bar"
      end
    end
  end
end

# Start the application. To quit, press 'q'.
Orange.start(Grid.App)
