defmodule Orange.Runtime.RenderLoop.ResizeTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.{Test, Terminal}

  test "Rerender on resizing" do
    [snapshot1, snapshot2] =
      Test.render(__MODULE__.Example,
        terminal_size: {20, 6},
        events: [
          {:wait_and_snapshot, 10},
          %Terminal.ResizeEvent{width: 14, height: 8},
          {:wait_and_snapshot, 10},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      --------------------
      -┌────────────────┐-
      -│Fixed-----------│-
      -│----------------│-
      -└────────────────┘-
      --------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      --------------
      -┌──────────┐-
      -│Fixed-----│-
      -│----------│-
      -│----------│-
      -│----------│-
      -└──────────┘-
      --------------\
      """
    )
  end

  defmodule Example do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil, events_subscription: true}

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
    def render(_state, _attrs, _update) do
      rect position: {:fixed, 1, 1, 1, 1}, style: [border: true] do
        "Fixed"
      end
    end
  end
end
