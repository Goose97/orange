defmodule Orange.Runtime.FocusTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.{Test, Terminal}

  test "focused components receive events and prevent other components from receiving events" do
    [snapshot1, snapshot2, snapshot3, snapshot4 | _] =
      Test.render(__MODULE__.CounterWrapper,
        terminal_size: {20, 6},
        events: [
          # Increase both counters by one
          %Terminal.KeyEvent{code: :up},
          # Focus on the first counter
          %Terminal.KeyEvent{code: {:char, "x"}},
          # Decrease only the focused counter by one
          %Terminal.KeyEvent{code: :down},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot2,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot3,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot4,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )
  end

  test "unfocus the focused component and all previously subscribed components receive events again" do
    [snapshot1, snapshot2, snapshot3, snapshot4, snapshot5, snapshot6 | _] =
      Test.render(__MODULE__.CounterWrapper,
        terminal_size: {20, 6},
        events: [
          # Increase both counters by one
          %Terminal.KeyEvent{code: :up},
          # Focus on the first counter
          %Terminal.KeyEvent{code: {:char, "x"}},
          # Decrease only the focused counter by one
          %Terminal.KeyEvent{code: :down},
          # Unfocus
          %Terminal.KeyEvent{code: {:char, "y"}},
          # Decrease both counters by one
          %Terminal.KeyEvent{code: :down},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot2,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot3,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot4,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot5,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot6,
      """
      ┌─────────────┐-----
      │Counter: -1--│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----\
      """
    )
  end

  test "call focus and unfocus from another process" do
    [snapshot1, snapshot2, snapshot3, snapshot4, snapshot5, snapshot6 | _] =
      Test.render({__MODULE__.CounterWrapper, from_another_process: true},
        terminal_size: {20, 6},
        events: [
          # Increase both counters by one
          %Terminal.KeyEvent{code: :up},
          # Focus on the first counter
          %Terminal.KeyEvent{code: {:char, "x"}},
          # Make sure the focus event is handled
          {:wait, 20},
          # Decrease only the focused counter by one
          %Terminal.KeyEvent{code: :down},
          # Unfocus
          %Terminal.KeyEvent{code: {:char, "y"}},
          # Make sure the unfocus event is handled
          {:wait, 20},
          # Decrease both counters by one
          %Terminal.KeyEvent{code: :down},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot2,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot3,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot4,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot5,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----\
      """
    )

    assert_content(
      snapshot6,
      """
      ┌─────────────┐-----
      │Counter: -1--│-----
      └─────────────┘-----
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----\
      """
    )
  end

  defmodule Counter do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(attrs),
      do: %{state: 0, events_subscription: Keyword.get(attrs, :events_subscription, false)}

    @impl true
    def handle_event(event, state, attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: :up} ->
          {:update, state + 1}

        %Terminal.KeyEvent{code: :down} ->
          {:update, state - 1}

        %Terminal.KeyEvent{code: {:char, "y"}} ->
          if attrs[:from_another_process],
            do: spawn(fn -> Orange.unfocus(:counter1) end),
            else: Orange.unfocus(:counter1)

          :noop

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          :noop

        _ ->
          :noop
      end
    end

    @impl true
    def render(state, attrs, _update) do
      rect style: [width: 15, border: attrs[:highlighted]] do
        rect do
          "Counter: #{state}"
        end
      end
    end
  end

  defmodule CounterWrapper do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil, events_subscription: true}

    @impl true
    def handle_event(event, _state, attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: {:char, "x"}} ->
          if attrs[:from_another_process],
            do: spawn(fn -> Orange.focus(:counter1) end),
            else: Orange.focus(:counter1)

          :noop

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          :noop

        _ ->
          :noop
      end
    end

    @impl true
    def render(_state, attrs, _update) do
      rect style: [flex_direction: :column] do
        {Counter,
         id: :counter1,
         events_subscription: true,
         highlighted: true,
         from_another_process: attrs[:from_another_process]}

        {Counter,
         id: :counter2,
         events_subscription: true,
         highlighted: true,
         from_another_process: attrs[:from_another_process]}
      end
    end
  end
end
