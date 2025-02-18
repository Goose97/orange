defmodule Orange.Runtime.CallbackTest do
  use ExUnit.Case

  alias Orange.{Test, Terminal}

  test "triggers after_mount/3 callback" do
    ref = :atomics.new(1, [])

    Test.render({__MODULE__.Counter, atomic: ref},
      terminal_size: {5, 5},
      events: [
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    value = :atomics.get(ref, 1)
    assert value == 1
  end

  test "triggers after_unmount/3 callback" do
    ref1 = :atomics.new(1, [])
    ref2 = :atomics.new(1, [])
    ref3 = :atomics.new(1, [])

    Test.render({__MODULE__.CounterWrapper, atomic1: ref1, atomic2: ref2, atomic3: ref3},
      terminal_size: {5, 5},
      events: [
        # Remove the second counter
        %Terminal.KeyEvent{code: {:char, "x"}},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
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
    def handle_event(event, _state, _attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          :noop

        _ ->
          :noop
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
          {:update, %{state | remove: true}}

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          :noop

        _ ->
          :noop
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
