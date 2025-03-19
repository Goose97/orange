defmodule Orange.Runtime.SubscribeTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.{Test, Terminal}

  test "render components and subscribe to events" do
    [snapshot1, snapshot2, snapshot3] =
      Test.render({__MODULE__.Counter, highlighted: true, events_subscription: true},
        terminal_size: {20, 6},
        events: [
          {:wait_and_snapshot, 10},
          # Increase by one
          %Terminal.KeyEvent{code: :up},
          {:wait_and_snapshot, 10},
          # Decrease by one
          %Terminal.KeyEvent{code: :down},
          {:wait_and_snapshot, 10},
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
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot3,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
      """
    )
  end

  test "unsubcribed components don't receive events" do
    [snapshot1, snapshot2, snapshot3, snapshot4] =
      Test.render(__MODULE__.CounterWrapper,
        terminal_size: {20, 6},
        events: [
          {:wait_and_snapshot, 10},
          # Increase by one
          %Terminal.KeyEvent{code: :up},
          {:wait_and_snapshot, 10},
          # Unsuscribe counter
          %Terminal.KeyEvent{code: {:char, "x"}},
          {:wait_and_snapshot, 10},
          # Decrease by one but the event is not handled
          %Terminal.KeyEvent{code: :down},
          {:wait_and_snapshot, 10},
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
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot3,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot4,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
      """
    )
  end

  test "call unsubcribed from another process" do
    [snapshot1, snapshot2, snapshot3, snapshot4] =
      Test.render({__MODULE__.CounterWrapper, from_other_process: true},
        terminal_size: {20, 6},
        events: [
          {:wait_and_snapshot, 10},
          # Increase by one
          %Terminal.KeyEvent{code: :up},
          {:wait_and_snapshot, 10},
          # Unsuscribe counter
          %Terminal.KeyEvent{code: {:char, "x"}},
          {:wait_and_snapshot, 10},
          # Make sure unsubscribe event is handled
          # Decrease by one but the event is not handled
          %Terminal.KeyEvent{code: :down},
          {:wait_and_snapshot, 10},
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
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot3,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot4,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
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
    def handle_event(event, state, _attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: :up} ->
          {:update, state + 1}

        %Terminal.KeyEvent{code: :down} ->
          {:update, state - 1}

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

    @impl true
    def init(_attrs), do: %{state: nil, events_subscription: true}

    @impl true
    def handle_event(event, _state, attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: {:char, "x"}} ->
          if attrs[:from_other_process],
            do: spawn(fn -> Orange.unsubscribe(:counter) end),
            else: Orange.unsubscribe(:counter)

          :noop

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          :noop

        _ ->
          :noop
      end
    end

    @impl true
    def render(_state, _attrs, _update) do
      {Counter, id: :counter, events_subscription: true, highlighted: true}
    end
  end
end
