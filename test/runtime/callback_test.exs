defmodule Orange.Runtime.CallbackTest do
  use ExUnit.Case
  import Mox

  alias Orange.{Terminal, RuntimeTestHelper}

  setup_all do
    Mox.defmock(Orange.MockTerminal, for: Terminal)
    Application.put_env(:orange, :terminal, Orange.MockTerminal)

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "triggers after_mount/3 callback" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {5, 5},
      events: [
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    ref = :atomics.new(1, [])
    RuntimeTestHelper.dry_render({__MODULE__.Counter, atomic: ref})

    value = :atomics.get(ref, 1)
    assert value == 1
  end

  test "triggers after_unmount/3 callback" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {5, 5},
      events: [
        # Remove the second counter
        %Terminal.KeyEvent{code: {:char, "x"}},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    ref1 = :atomics.new(1, [])
    ref2 = :atomics.new(1, [])
    ref3 = :atomics.new(1, [])

    RuntimeTestHelper.dry_render(
      {__MODULE__.CounterWrapper, atomic1: ref1, atomic2: ref2, atomic3: ref3}
    )

    assert :atomics.get(ref2, 1) == -1
    assert :atomics.get(ref3, 1) == -1
  end

  defmodule Counter do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: 0, events_subscription: true}

    @impl true
    def handle_event(event, state, _attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
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
    def init(_attrs), do: %{state: %{remove: false}, events_subscription: true}

    @impl true
    def handle_event(event, state, _attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: {:char, "x"}} ->
          %{state | remove: true}

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
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

        if state.remove do
          rect(do: "Removed!")
        else
          rect do
            {Counter, atomic: attrs[:atomic3]}
          end
        end
      end
    end
  end
end
