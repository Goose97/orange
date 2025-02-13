defmodule Orange.Component.ModalTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.Test

  test ":open is true" do
    snapshot = Test.render_once({__MODULE__.Modal, open: true}, terminal_size: {20, 15})

    assert_content(
      snapshot,
      """
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
    )
  end

  test ":open is false" do
    snapshot =
      Test.render_once({__MODULE__.Modal, open: false}, terminal_size: {20, 15})

    assert_content(
      snapshot,
      """
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
    )
  end

  test "offset_x is too big for width" do
    snapshot =
      Test.render_once({__MODULE__.Modal, open: true, offset_x: 10, offset_y: 1},
        terminal_size: {20, 6}
      )

    assert_content(
      snapshot,
      """
      Displaying modal...-
      --------------------
      --------------------
      --------------------
      --------------------
      --------------------\
      """
    )
  end

  test "offset_y is too big for height" do
    snapshot =
      Test.render_once({__MODULE__.Modal, open: true, offset_y: 6}, terminal_size: {20, 12})

    assert_content(
      snapshot,
      """
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
    )
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
