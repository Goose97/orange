defmodule Orange.Runtime.UpdateStateTest do
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

  test "update state with callback" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
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

    ref = :atomics.new(1, [])
    [buffer1, buffer2 | _] = RuntimeTestHelper.dry_render({__MODULE__.Counter, atomic: ref})

    assert Buffer.to_string(buffer1) == """
           ┌─────────────┐-----
           │Counter: 0---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
           """

    assert Buffer.to_string(buffer2) == """
           ┌─────────────┐-----
           │Counter: 1---│-----
           └─────────────┘-----
           --------------------
           --------------------
           --------------------\
           """
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
