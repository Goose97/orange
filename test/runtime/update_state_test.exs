defmodule Orange.Runtime.UpdateStateTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.{Test, Terminal}

  test "update state with callback" do
    ref = :atomics.new(1, [])

    [snapshot] =
      Test.render({__MODULE__.Counter, atomic: ref},
        terminal_size: {20, 6},
        events: [
          # Wait to make sure after_mount fires first
          {:wait_and_snapshot, 20},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot,
      """
      ┌─────────────┐-----
      │Counter: 1---│-----
      └─────────────┘-----
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
    def after_mount(state, _attrs, update) do
      update.(state + 1)
    end

    @impl true
    def render(state, _attrs, _update) do
      rect style: [width: 15, border: true] do
        rect do
          "Counter: #{state}"
        end
      end
    end
  end
end
