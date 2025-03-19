defmodule Orange.Component.InputTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.{Terminal, Test}

  test "receives keyboard events and renders input" do
    [snapshot1, snapshot2, snapshot3, snapshot4, snapshot5] =
      Test.render(__MODULE__.Input,
        terminal_size: {25, 5},
        events: [
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "f"}},
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "o"}},
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "o"}},
          {:wait_and_snapshot, 10},
          # Submit input
          %Terminal.KeyEvent{code: :enter},
          {:wait_and_snapshot, 10},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      Input: ------------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      Input: f-----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot3,
      """
      Input: fo----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot4,
      """
      Input: foo---------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot5,
      """
      Input: foo---------------
      Submitted value: foo-----
      -------------------------
      -------------------------
      -------------------------\
      """
    )
  end

  test "backspace deletes characters" do
    [snapshot1, snapshot2, snapshot3, snapshot4, snapshot5, snapshot6] =
      Test.render(__MODULE__.Input,
        terminal_size: {25, 5},
        events: [
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "f"}},
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "o"}},
          {:wait_and_snapshot, 10},
          # Delete character
          %Terminal.KeyEvent{code: :backspace},
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "a"}},
          {:wait_and_snapshot, 10},
          # Submit input
          %Terminal.KeyEvent{code: :enter},
          {:wait_and_snapshot, 10},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      Input: ------------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      Input: f-----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot3,
      """
      Input: fo----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot4,
      """
      Input: f-----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot5,
      """
      Input: fa----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot6,
      """
      Input: fa----------------
      Submitted value: fa------
      -------------------------
      -------------------------
      -------------------------\
      """
    )
  end

  test "custom submit_key" do
    [snapshot1, snapshot2, snapshot3] =
      Test.render({__MODULE__.Input, submit_key: {:char, "x"}},
        terminal_size: {25, 5},
        events: [
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "f"}},
          {:wait_and_snapshot, 10},
          # Submit input
          %Terminal.KeyEvent{code: {:char, "x"}},
          {:wait_and_snapshot, 10},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      Input: ------------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      Input: f-----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot3,
      """
      Input: f-----------------
      Submitted value: f-------
      -------------------------
      -------------------------
      -------------------------\
      """
    )
  end

  test "custom exit_key" do
    counter = :counters.new(1, [])

    [snapshot1, snapshot2, snapshot3] =
      Test.render(
        {__MODULE__.Input,
         exit_key: {:char, "x"}, on_exit: fn -> :counters.add(counter, 1, 1) end},
        terminal_size: {25, 5},
        events: [
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "f"}},
          # Exit
          {:wait_and_snapshot, 10},
          %Terminal.KeyEvent{code: {:char, "x"}},
          {:wait_and_snapshot, 10},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      Input: ------------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      Input: f-----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot3,
      """
      Input: f-----------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert :counters.get(counter, 1) == 1
  end

  test ":auto_focus false" do
    [snapshot1, snapshot2] =
      Test.render({__MODULE__.Input, submit_key: {:char, "x"}, auto_focus: false},
        terminal_size: {25, 5},
        events: [
          {:wait_and_snapshot, 10},
          # Auto focus is disabled, this event shouldn't be processed
          %Terminal.KeyEvent{code: {:char, "f"}},
          {:wait_and_snapshot, 10},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      Input: ------------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      Input: ------------------
      Submitted value: --------
      -------------------------
      -------------------------
      -------------------------\
      """
    )
  end

  @tag capture_log: true
  test ":auto_focus requires :id" do
    %RuntimeError{message: message} =
      Test.render_catch_error({__MODULE__.Input, submit_key: {:char, "x"}, id: nil},
        terminal_size: {25, 5}
      )

    assert message =~ "Expected an :id attribute when :auto_focus is true"
  end

  defmodule Input do
    @behaviour Orange.Component

    import Orange.Macro
    alias Orange.{Terminal, Component}

    @impl true
    def init(_attrs), do: %{state: %{input_value: ""}, events_subscription: true}

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
    def render(state, attrs, update) do
      input_attrs = [
        on_submit: fn value -> update.(%{state | input_value: value}) end,
        prefix: "Input:",
        auto_focus: Keyword.get(attrs, :auto_focus, true),
        id: Keyword.get(attrs, :id, :input)
      ]

      input_attrs =
        Keyword.merge(input_attrs, Keyword.take(attrs, [:submit_key, :exit_key, :on_exit]))

      rect style: [width: 20, height: attrs[:height], flex_direction: :column] do
        {Component.Input, input_attrs}

        rect do
          "Submitted value: #{state.input_value}"
        end
      end
    end
  end
end
