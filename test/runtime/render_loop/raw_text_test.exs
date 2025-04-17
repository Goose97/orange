defmodule Orange.Runtime.RenderLoop.RawTextTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.{Test, Terminal}

  test "renders raw text" do
    [snapshot1, snapshot2] =
      Test.render(__MODULE__.Example,
        terminal_size: {20, 6},
        events: [
          {:wait_and_snapshot, 20},
          %Terminal.KeyEvent{code: :enter},
          {:wait_and_snapshot, 20}
        ]
      )

    assert_content(
      snapshot1,
      """
      foo-----------------
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
      bar-----------------
      --------------------
      --------------------
      --------------------
      --------------------
      --------------------\
      """
    )
  end

  defmodule Example do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: %{text: "foo"}, events_subscription: true}

    @impl true
    def handle_event(event, _state, _attrs, _update) do
      case event do
        %Terminal.KeyEvent{code: :enter} ->
          {:update, %{text: "bar"}}

        _ ->
          :noop
      end
    end

    @impl true
    def render(state, _attrs, _update) do
      rect style: [width: 10, height: 1] do
        {:raw_text, :row, state.text}
      end
    end
  end
end
