defmodule Orange.Runtime.SubscribeTest do
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

  test "render components and subscribe to events" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 6},
      events: [
        # Increase by one
        %Terminal.KeyEvent{code: :up},
        # Decrease by one
        %Terminal.KeyEvent{code: :down},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    [buffer1, buffer2, buffer3 | _] =
      RuntimeTestHelper.dry_render(
        {__MODULE__.Counter, highlighted: true, events_subscription: true}
      )

    assert Buffer.to_string(buffer1) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
           """

    assert Buffer.to_string(buffer2) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
           """

    assert Buffer.to_string(buffer3) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
           """
  end

  test "unsubcribed components don't receive events" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 6},
      events: [
        # Increase by one
        %Terminal.KeyEvent{code: :up},
        # Unsuscribe counter
        %Terminal.KeyEvent{code: {:char, "x"}},
        # Decrease by one but the event is not handled
        %Terminal.KeyEvent{code: :down},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    [buffer1, buffer2, buffer3, buffer4 | _] = RuntimeTestHelper.dry_render(__MODULE__.CounterWrapper)

    assert Buffer.to_string(buffer1) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
           """

    assert Buffer.to_string(buffer2) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
           """

    assert Buffer.to_string(buffer3) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
           """

    assert Buffer.to_string(buffer4) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
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

    @impl true
    def init(_attrs), do: %{state: nil, events_subscription: true}

    @impl true
    def handle_event(event, state, _attrs) do
      case event do
        %Terminal.KeyEvent{code: {:char, "x"}} ->
          Orange.unsubscribe(:counter)
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
      {Counter, id: :counter, events_subscription: true, highlighted: true}
    end
  end
end
