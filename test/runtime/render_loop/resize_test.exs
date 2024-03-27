defmodule Orange.Runtime.RenderLoop.ResizeTest do
  use ExUnit.Case
  import Mox

  alias Orange.{Terminal, RuntimeTestHelper, Renderer.Buffer}

  setup_all do
    Mox.defmock(Orange.MockTerminal, for: Terminal)
    Application.put_env(:orange, :terminal, Orange.MockTerminal)

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "Rerender on resizing" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 6},
      events: [
        %Terminal.ResizeEvent{width: 14, height: 8},
        # Quit
        %Terminal.KeyEvent{code: {:char, "q"}}
      ]
    )

    [buffer1, buffer2 | _] = RuntimeTestHelper.dry_render(__MODULE__.Example)

    assert Buffer.to_string(buffer1) == """
           --------------------
           -┌────────────────┐-
           -│Fixed-----------│-
           -│----------------│-
           -└────────────────┘-
           --------------------\
           """

    assert Buffer.to_string(buffer2) == """
           --------------
           -┌──────────┐-
           -│Fixed-----│-
           -│----------│-
           -│----------│-
           -│----------│-
           -└──────────┘-
           --------------\
           """
  end

  defmodule Example do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil, events_subscription: true}

    @impl true
    def handle_event(event, state, _attrs) do
      case event do
        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          state

        _ ->
          state
      end
    end

    @impl true
    def render(_state, _attrs, _update) do
      rect position: {:fixed, 1, 1, 1, 1}, style: [border: true] do
        "Fixed"
      end
    end
  end
end
