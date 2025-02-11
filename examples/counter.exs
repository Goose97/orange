defmodule Counter.App do
  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: 0, events_subscription: true}

  @impl true
  def handle_event(event, state, _attrs, _update) do
    case event do
      %Orange.Terminal.KeyEvent{code: :up} ->
        state + 1

      %Orange.Terminal.KeyEvent{code: :down} ->
        state - 1

      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        Orange.stop()
        state

      _ ->
        state
    end
  end

  @impl true
  def after_mount(_state, _attrs, update) do
    # Set counter value to 10 after 5 seconds
    spawn(fn ->
      Process.sleep(5000)
      update.(10)
    end)
  end

  @impl true
  def render(state, _attrs, _update) do
    rect style: [width: 20, height: 20, border: true, justify_content: :space_between] do
      "-"

      rect do
        "Counter: #{state}"
      end

      "+"
    end
  end
end

# Start the application. To quit, press 'q'.
Orange.start(Counter.App)
