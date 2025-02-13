defmodule Orange.Component.VerticalScrollableRectTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.Test

  describe "when content is NOT overflow" do
    test "it does NOT render the scroll bar" do
      snapshot =
        Test.render_once(
          {__MODULE__.Scrollable, offset: 0, height: 20, total_items: 15},
          terminal_size: {25, 25}
        )

      assert_content(
        snapshot,
        """
        ┌──────────────────┐-----
        │Item 1------------│-----
        │Item 2------------│-----
        │Item 3------------│-----
        │Item 4------------│-----
        │Item 5------------│-----
        │Item 6------------│-----
        │Item 7------------│-----
        │Item 8------------│-----
        │Item 9------------│-----
        │Item 10-----------│-----
        │Item 11-----------│-----
        │Item 12-----------│-----
        │Item 13-----------│-----
        │Item 14-----------│-----
        │Item 15-----------│-----
        │------------------│-----
        │------------------│-----
        │------------------│-----
        └──────────────────┘-----
        -------------------------
        -------------------------
        -------------------------
        -------------------------
        -------------------------\
        """
      )
    end
  end

  describe "when content is overflow" do
    test "offset is 0" do
      snapshot =
        Test.render_once(
          {__MODULE__.Scrollable, offset: 0, height: 10, total_items: 15},
          terminal_size: {25, 12}
        )

      assert_content(
        snapshot,
        """
        ┌──────────────────▲-----
        │Item 1------------█-----
        │Item 2------------█-----
        │Item 3------------█-----
        │Item 4------------█-----
        │Item 5------------│-----
        │Item 6------------│-----
        │Item 7------------│-----
        │Item 8------------│-----
        └──────────────────▼-----
        -------------------------
        -------------------------\
        """
      )
    end

    test "offset is non-zero" do
      snapshot =
        Test.render_once(
          {__MODULE__.Scrollable, offset: 3, height: 10, total_items: 15},
          terminal_size: {25, 12}
        )

      assert_content(
        snapshot,
        """
        ┌──────────────────▲-----
        │Item 4------------│-----
        │Item 5------------│-----
        │Item 6------------█-----
        │Item 7------------█-----
        │Item 8------------█-----
        │Item 9------------█-----
        │Item 10-----------│-----
        │Item 11-----------│-----
        └──────────────────▼-----
        -------------------------
        -------------------------\
        """
      )
    end

    test "caps the offset by content height and viewport height" do
      snapshot =
        Test.render_once(
          {__MODULE__.Scrollable, offset: 15, height: 10, total_items: 15},
          terminal_size: {25, 15}
        )

      assert_content(
        snapshot,
        """
        ┌──────────────────▲-----
        │Item 8------------│-----
        │Item 9------------│-----
        │Item 10-----------│-----
        │Item 11-----------│-----
        │Item 12-----------█-----
        │Item 13-----------█-----
        │Item 14-----------█-----
        │Item 15-----------█-----
        └──────────────────▼-----
        -------------------------
        -------------------------
        -------------------------
        -------------------------
        -------------------------\
        """
      )
    end
  end

  defmodule Scrollable do
    @behaviour Orange.Component

    import Orange.Macro
    alias Orange.Component.VerticalScrollableRect

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, attrs, _update) do
      items =
        for i <- 1..attrs[:total_items] do
          rect do
            "Item #{i}"
          end
        end

      rect style: [width: 20, height: attrs[:height]] do
        {
          VerticalScrollableRect,
          content_height: attrs[:total_items],
          height: attrs[:height],
          scroll_offset: attrs[:offset],
          children: items
        }
      end
    end
  end
end
