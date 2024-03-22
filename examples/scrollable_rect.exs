defmodule ScrollableRect.App do
  @behaviour Orange.Component

  import Orange.Macro
  alias Orange.Component.VerticalScrollableRect

  @container_height 10
  @total_items 15

  @impl true
  def init(_attrs), do: %{state: 0, events_subscription: true}

  @impl true
  def handle_event(event, state, _attrs) do
    case event do
      %Orange.Terminal.KeyEvent{code: :up} ->
        if state > 0, do: state - 1, else: state

      %Orange.Terminal.KeyEvent{code: :down} ->
        # Plus 2 because of the borders
        if state + @container_height - 2 < @total_items, do: state + 1, else: state

      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        Orange.stop()
        state

      _ ->
        state
    end
  end

  @impl true
  def render(state, _attrs, _update) do
    items =
      for i <- 1..@total_items do
        rect do
          "Item #{i}"
        end
      end

    rect style: [width: 20, height: @container_height] do
      {
        VerticalScrollableRect,
        content_height: @total_items,
        height: @container_height,
        scroll_offset: state,
        children: items
      }
    end
  end
end

# Start the application. To quit, press 'q'.
Orange.start(ScrollableRect.App)
