defmodule Orange.Runtime.CallbackTest do
  use ExUnit.Case
  import Mox

  alias Orange.{Runtime, Terminal}
  alias Orange.RuntimeTestHelper

  setup_all do
    Mox.defmock(Orange.MockTerminal, for: Terminal)
    Application.put_env(:orange, :terminal, Orange.MockTerminal)

    Mox.defmock(Orange.Runtime.MockEventManager, for: Runtime.EventManager)
    Application.put_env(:orange, :event_manager, Orange.Runtime.MockEventManager)

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "triggers after_mount/3 callback" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {5, 5}
    )

    RuntimeTestHelper.setup_mock_event_manager(Orange.Runtime.MockEventManager,
      events: [
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    ref = :atomics.new(1, [])
    [_] = RuntimeTestHelper.dry_render({__MODULE__.Counter, atomic: ref})

    value = :atomics.get(ref, 1)
    assert value == 1
  end

  test "triggers after_unmount/3 callback" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {5, 5}
    )

    RuntimeTestHelper.setup_mock_event_manager(Orange.Runtime.MockEventManager,
      events: [
        # Remove the second counter
        %Terminal.KeyEvent{code: {:char, "x"}},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    ref1 = :atomics.new(1, [])
    ref2 = :atomics.new(1, [])

    [_, _] =
      RuntimeTestHelper.dry_render({__MODULE__.CounterWrapper, atomic1: ref1, atomic2: ref2})

    value = :atomics.get(ref2, 1)
    assert value == -1
  end

  defmodule Counter do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: 0, events_subscription: true}

    @impl true
    def handle_event(event, state, _attrs) do
      case event do
        %Terminal.KeyEvent{code: {:char, "q"}} ->
          throw(:stop)
          state

        _ ->
          state
      end
    end

    @impl true
    def after_mount(_state, attrs, _update) do
      :atomics.put(attrs[:atomic], 1, 1)
    end

    @impl true
    def after_unmount(_state, attrs, _update) do
      :atomics.put(attrs[:atomic], 1, -1)
    end

    @impl true
    def render(state, _attrs, _update) do
      rect style: [width: 15] do
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
    def init(_attrs), do: %{state: %{remove: false}, events_subscription: true}

    @impl true
    def handle_event(event, state, _attrs) do
      case event do
        %Terminal.KeyEvent{code: {:char, "x"}} ->
          %{state | remove: true}

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          throw(:stop)
          state

        _ ->
          state
      end
    end

    @impl true
    def render(state, attrs, _update) do
      rect style: [width: 15] do
        {Counter, atomic: attrs[:atomic1]}
        if !state.remove, do: {Counter, atomic: attrs[:atomic2]}
      end
    end
  end
end
