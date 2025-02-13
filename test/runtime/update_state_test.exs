defmodule Orange.Runtime.UpdateStateTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.{Test, Terminal}

  test "update state with callback" do
    ref = :atomics.new(1, [])

    [snapshot1, snapshot2 | _] =
      Test.render({__MODULE__.Counter, atomic: ref},
        terminal_size: {20, 6},
        events: [
          # Wait to make sure after_mount fires first
          {:wait, 20},
          # Noop event
          %Terminal.KeyEvent{code: :up},
          # Quit
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

    assert_content(
      snapshot1,
      """
      ┌─────────────┐-----
      │Counter: 0---│-----
      └─────────────┘-----
      --------------------
      --------------------
      --------------------\
      """
    )

    assert_content(
      snapshot2,
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
    def handle_event(event, state, _attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: :up} ->
          state

        %Terminal.KeyEvent{code: {:char, "q"}} ->
          Orange.stop()
          state

        _ ->
          state
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
