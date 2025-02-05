defmodule Orange.Component.ModalTest do
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

  test ":open is true" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 15}
    )

    buffer = RuntimeTestHelper.dry_render_once({__MODULE__.Modal, open: true})

    assert Buffer.to_string(buffer) === """
           Displaying modal...-
           --------------------
           --------------------
           --------------------
           ----┌──────────┐----
           ----│foobar----│----
           ----│----------│----
           ----│----------│----
           ----│----------│----
           ----│----------│----
           ----└──────────┘----
           --------------------
           --------------------
           --------------------
           --------------------\
           """
  end

  test ":open is false" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 15}
    )

    buffer = RuntimeTestHelper.dry_render_once({__MODULE__.Modal, open: false})

    assert Buffer.to_string(buffer) === """
           Displaying modal...-
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------\
           """
  end

  test "offset_x is too big for width" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 6}
    )

    buffer =
      RuntimeTestHelper.dry_render_once({__MODULE__.Modal, open: true, offset_x: 10, offset_y: 1})

    assert Buffer.to_string(buffer) === """
           Displaying modal...-
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------\
           """
  end

  test "offset_y is too big for height" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 12}
    )

    buffer = RuntimeTestHelper.dry_render_once({__MODULE__.Modal, open: true, offset_y: 6})

    assert Buffer.to_string(buffer) === """
           Displaying modal...-
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------\
           """
  end

  defmodule Modal do
    @behaviour Orange.Component

    import Orange.Macro
    alias Orange.Component

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, attrs, _update) do
      offset_x = Keyword.get(attrs, :offset_x, 4)
      offset_y = Keyword.get(attrs, :offset_y, 4)

      modal_content =
        rect do
          "foo"
          "bar"
        end

      rect style: [width: "100%", height: "100%"] do
        rect do
          "Displaying modal..."
        end

        {
          Component.Modal,
          offset_x: offset_x, offset_y: offset_y, children: [modal_content], open: attrs[:open]
        }
      end
    end
  end
end
