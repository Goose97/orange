defmodule Counter.Child do
  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: 0}

  @impl true
  def handle_event(event, state, _attrs) do
    case event do
      %Orange.Terminal.KeyEvent{code: :up} ->
        state + 1

      %Orange.Terminal.KeyEvent{code: :down} ->
        state - 1

      %Orange.Terminal.KeyEvent{code: {:char, "k"}} ->
        state + 1

      %Orange.Terminal.KeyEvent{code: {:char, "j"}} ->
        state - 1

      _ ->
        state
    end
  end

  @impl true
  def after_mount(_state, _attrs, update) do
    spawn(fn ->
      Process.sleep(3000)
      update.(100)
    end)
  end

  @impl true
  def render(state, attrs, update) do
    rect style: [width: 20, height: 20, border: attrs[:highlighted]] do
      span do
        "Counter: #{state}"
      end
    end
  end
end

defmodule Counter.App do
  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: %{focus: nil, count: 2}, events_subscription: true}

  @impl true
  def handle_event(event, state, _attrs) do
    case event do
      %Orange.Terminal.KeyEvent{code: {:char, "h"}} ->
        old_focus = state.focus

        case state.focus do
          nil -> %{state | focus: :counter1}
          :counter1 -> %{state | focus: :counter2}
          :counter2 -> %{state | focus: :counter1}
        end
        |> tap(fn state ->
          if old_focus, do: Orange.unsubscribe(old_focus)
          Orange.subscribe(state.focus)
        end)

      %Orange.Terminal.KeyEvent{code: {:char, "l"}} ->
        old_focus = state.focus

        case state.focus do
          nil -> %{state | focus: :counter1}
          :counter1 -> %{state | focus: :counter2}
          :counter2 -> %{state | focus: :counter1}
        end
        |> tap(fn state ->
          if old_focus, do: Orange.unsubscribe(old_focus)
          Orange.subscribe(state.focus)
        end)

      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        Orange.stop()
        state

      _ ->
        state
    end
  end

  @impl true
  def render(state, _attrs, _update) do
    rect direction: :row do
      {Counter.Child, [id: :counter1, highlighted: state.focus == :counter1]}
      {Counter.Child, [id: :counter2, highlighted: state.focus == :counter2]}
    end
  end
end

# Start the application. To quit, press 'q'.
Orange.start(Counter.App)
