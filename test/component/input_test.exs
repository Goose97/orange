defmodule Orange.Component.InputTest do
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

  test "receives keyboard events and renders input" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {25, 5},
      events: [
        %Terminal.KeyEvent{code: {:char, "f"}},
        %Terminal.KeyEvent{code: {:char, "o"}},
        %Terminal.KeyEvent{code: {:char, "o"}},
        # Submit input
        %Terminal.KeyEvent{code: :enter},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    [buffer1, buffer2, buffer3, buffer4, buffer5 | _] =
      RuntimeTestHelper.dry_render(__MODULE__.Input)

    assert Buffer.to_string(buffer1) === """
           Input: ------------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer2) === """
           Input: f-----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer3) === """
           Input: fo----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer4) === """
           Input: foo---------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer5) === """
           Input: foo---------------
           Submitted value: foo-----
           -------------------------
           -------------------------
           -------------------------\
           """
  end

  test "backspace deletes characters" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {25, 5},
      events: [
        %Terminal.KeyEvent{code: {:char, "f"}},
        %Terminal.KeyEvent{code: {:char, "o"}},
        # Delete character
        %Terminal.KeyEvent{code: :backspace},
        %Terminal.KeyEvent{code: {:char, "a"}},
        # Submit input
        %Terminal.KeyEvent{code: :enter},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    [buffer1, buffer2, buffer3, buffer4, buffer5, buffer6 | _] =
      RuntimeTestHelper.dry_render(__MODULE__.Input)

    assert Buffer.to_string(buffer1) === """
           Input: ------------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer2) === """
           Input: f-----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer3) === """
           Input: fo----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer4) === """
           Input: f-----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer5) === """
           Input: fa----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer6) === """
           Input: fa----------------
           Submitted value: fa------
           -------------------------
           -------------------------
           -------------------------\
           """
  end

  test "custom submit_key" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {25, 5},
      events: [
        %Terminal.KeyEvent{code: {:char, "f"}},
        # Submit input
        %Terminal.KeyEvent{code: {:char, "x"}},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    [buffer1, buffer2, buffer3 | _] =
      RuntimeTestHelper.dry_render({__MODULE__.Input, submit_key: {:char, "x"}})

    assert Buffer.to_string(buffer1) === """
           Input: ------------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer2) === """
           Input: f-----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer3) === """
           Input: f-----------------
           Submitted value: f-------
           -------------------------
           -------------------------
           -------------------------\
           """
  end

  test "custom exit_key" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {25, 5},
      events: [
        %Terminal.KeyEvent{code: {:char, "f"}},
        # Exit
        %Terminal.KeyEvent{code: {:char, "x"}},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    counter = :counters.new(1, [])

    [buffer1, buffer2, buffer3 | _] =
      RuntimeTestHelper.dry_render(
        {__MODULE__.Input,
         exit_key: {:char, "x"}, on_exit: fn -> :counters.add(counter, 1, 1) end}
      )

    assert Buffer.to_string(buffer1) === """
           Input: ------------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer2) === """
           Input: f-----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer3) === """
           Input: f-----------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert :counters.get(counter, 1) == 1
  end

  test ":auto_focus false" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {25, 5},
      events: [
        # Auto focus is disabled, this event shouldn't be processed
        %Terminal.KeyEvent{code: {:char, "f"}},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    [buffer1, buffer2, buffer3 | _] =
      RuntimeTestHelper.dry_render(
        {__MODULE__.Input, submit_key: {:char, "x"}, auto_focus: false}
      )

    assert Buffer.to_string(buffer1) === """
           Input: ------------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer2) === """
           Input: ------------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """

    assert Buffer.to_string(buffer3) === """
           Input: ------------------
           Submitted value: --------
           -------------------------
           -------------------------
           -------------------------\
           """
  end

  @tag capture_log: true
  test ":auto_focus requires :id" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {25, 5}
    )

    %RuntimeError{message: message} =
      RuntimeTestHelper.catch_render_error({__MODULE__.Input, submit_key: {:char, "x"}, id: nil})

    assert message =~ "Expected an :id attribute when :auto_focus is true"
  end

  defmodule Input do
    @behaviour Orange.Component

    import Orange.Macro
    alias Orange.{Terminal, Component}

    @impl true
    def init(_attrs), do: %{state: %{input_value: ""}, events_subscription: true}

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
