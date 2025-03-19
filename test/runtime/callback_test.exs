defmodule Orange.Runtime.CallbackTest do
  use ExUnit.Case

  import Orange.Test.Assertions

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

  test "triggers before_update/3 callback" do
    [snapshot1, snapshot2] =
      Test.render(__MODULE__.Text,
        terminal_size: {20, 10},
        events: [
          {:wait_and_snapshot, 10},
          # Trigger state update
          %Terminal.KeyEvent{code: {:char, "a"}},
          {:wait_and_snapshot, 10},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      Text: --------------
      Double text: -------
      --------------------
      --------------------
      --------------------
      --------------------
      --------------------
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      Text: a-------------
      Double text: aa-----
      --------------------
      --------------------
      --------------------
      --------------------
      --------------------
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

  defmodule TextDouble do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(attrs), do: %{state: %{text: attrs[:text]}, events_subscription: false}

    @impl true
    def before_update(state, attrs, _update) do
      if state.text != attrs[:text], do: {:update, %{state | text: attrs[:text]}}, else: :noop
    end

    @impl true
    def render(state, _attrs, _update) do
      text = if state.text, do: String.duplicate(state.text, 2), else: ""

      rect do
        "Double text: #{text}"
      end
    end
  end

  defmodule Text do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: %{text: nil}, events_subscription: true}

    @impl true
    def handle_event(event, state, _attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          :noop

        %Terminal.KeyEvent{code: {:char, char}} ->
          {:update, %{state | text: char}}

        _ ->
          :noop
      end
    end

    @impl true
    def render(state, _attrs, _update) do
      rect style: [flex_direction: :column] do
        "Text: #{state.text}"
        {TextDouble, text: state.text}
      end
    end
  end
end
