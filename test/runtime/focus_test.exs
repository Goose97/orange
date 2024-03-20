defmodule Orange.Runtime.FocusTest do
  use ExUnit.Case
  import Mox

  alias Orange.Renderer.Buffer
  alias Orange.{Terminal, RuntimeTestHelper}

  setup_all do
    Mox.defmock(Orange.MockTerminal, for: Terminal)
    Application.put_env(:orange, :terminal, Orange.MockTerminal)

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "focused components receive events and prevent other components from receiving events" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
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

    [buffer1, buffer2, buffer3, buffer4] = RuntimeTestHelper.dry_render(__MODULE__.CounterWrapper)

    assert Buffer.to_string(buffer1) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----\
           """

    assert Buffer.to_string(buffer2) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----\
           """

    assert Buffer.to_string(buffer3) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----\
           """

    assert Buffer.to_string(buffer4) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----\
           """
  end

  test "unfocus the focused component and all previously subscribed components receive events again" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
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

    [buffer1, buffer2, buffer3, buffer4, buffer5, buffer6] =
      RuntimeTestHelper.dry_render(__MODULE__.CounterWrapper)

    assert Buffer.to_string(buffer1) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----\
           """

    assert Buffer.to_string(buffer2) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----\
           """

    assert Buffer.to_string(buffer3) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----\
           """

    assert Buffer.to_string(buffer4) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----\
           """

    assert Buffer.to_string(buffer5) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----\
           """

    assert Buffer.to_string(buffer6) == """
           ┌─────────────┐-----
           │Counter: -1--│-----
           └─────────────┘-----
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----\
           """
  end

  defmodule Counter do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(attrs),
      do: %{state: 0, events_subscription: Keyword.get(attrs, :events_subscription, false)}

    @impl true
    def handle_event(event, state, _attrs) do
      case event do
        %Terminal.KeyEvent{code: :up} ->
          state + 1

        %Terminal.KeyEvent{code: :down} ->
          state - 1

        %Terminal.KeyEvent{code: {:char, "y"}} ->
          Orange.unfocus(:counter1)
          state

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          state

        _ ->
          state
      end
    end

    @impl true
    def render(state, attrs, _update) do
      rect style: [width: 15, border: attrs[:highlighted]] do
        span do
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
    def handle_event(event, state, _attrs) do
      case event do
        %Terminal.KeyEvent{code: {:char, "x"}} ->
          Orange.focus(:counter1)
          state

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          state

        _ ->
          state
      end
    end

    @impl true
    def render(_state, _attrs, _update) do
      rect do
        {Counter, id: :counter1, events_subscription: true, highlighted: true}
        {Counter, id: :counter2, events_subscription: true, highlighted: true}
      end
    end
  end
end
