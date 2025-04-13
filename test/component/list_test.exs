defmodule Orange.Component.ListTest do
  use ExUnit.Case

  import Orange.Macro
  import Orange.Test.Assertions

  alias Orange.{Terminal, Test}

  describe "renders items" do
    test "renders list items" do
      items = [
        %{key: :item1, item: "Item 1", height: 1},
        %{key: :item2, item: "Item 2", height: 1},
        %{key: :item3, item: "Item 3", height: 1}
      ]

      [snapshot] =
        Test.render(
          {
            Orange.Component.List,
            items: items, selected_item: :item2
          },
          terminal_size: {20, 5},
          events: [{:wait_and_snapshot, 10}]
        )

      assert_content(
        snapshot,
        """
        -Item 1-------------
         Item 2 ------------
        -Item 3-------------
        --------------------
        --------------------\
        """
      )
    end

    test "complex items" do
      items = [
        %{key: :item1, item: "Item 1", height: 1},
        %{
          key: :item2,
          item:
            rect style: [flex_direction: :column] do
              "Multiple"
              "lines"
              "item"
            end,
          height: 3
        },
        %{key: :item3, item: "Item 3", height: 1}
      ]

      [snapshot] =
        Test.render(
          {
            Orange.Component.List,
            items: items, selected_item: :item2
          },
          terminal_size: {20, 5},
          events: [{:wait_and_snapshot, 10}]
        )

      assert_content(
        snapshot,
        """
        -Item 1-------------
         Multiple ----------
         lines    ----------
         item     ----------
        -Item 3-------------\
        """
      )
    end
  end

  describe "navigation" do
    test "pressing j/k moves the selection to the next/previous item" do
      [snapshot1, snapshot2, snapshot3] =
        Test.render(__MODULE__.List,
          terminal_size: {25, 10},
          events: [
            {:wait_and_snapshot, 20},
            # Move down twice
            %Terminal.KeyEvent{code: {:char, "j"}},
            %Terminal.KeyEvent{code: {:char, "j"}},
            {:wait_and_snapshot, 20},
            %Terminal.KeyEvent{code: {:char, "k"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot1,
        """
        ┌───────────────┐--------
        │ Item 1        │--------
        │-Item 2--------│--------
        │-Item 3--------│--------
        │-Item 4--------│--------
        │-Item 5--------│--------
        │Selected: item1│--------
        └───────────────┘--------
        -------------------------
        -------------------------\
        """
      )

      assert_content(
        snapshot2,
        """
        ┌───────────────┐--------
        │-Item 1--------│--------
        │-Item 2--------│--------
        │ Item 3        │--------
        │-Item 4--------│--------
        │-Item 5--------│--------
        │Selected: item3│--------
        └───────────────┘--------
        -------------------------
        -------------------------\
        """
      )

      assert_content(
        snapshot3,
        """
        ┌───────────────┐--------
        │-Item 1--------│--------
        │ Item 2        │--------
        │-Item 3--------│--------
        │-Item 4--------│--------
        │-Item 5--------│--------
        │Selected: item2│--------
        └───────────────┘--------
        -------------------------
        -------------------------\
        """
      )
    end

    test "with complex items" do
      items = [
        %{key: :item1, item: "Item 1", height: 1},
        %{
          key: :item2,
          item:
            rect style: [flex_direction: :column] do
              "Multiple"
              "lines"
              "item"
            end,
          height: 3
        },
        %{key: :item3, item: "Item 3", height: 1}
      ]

      [snapshot1, snapshot2] =
        Test.render({__MODULE__.List, items: items},
          terminal_size: {25, 10},
          events: [
            %Terminal.KeyEvent{code: {:char, "j"}},
            {:wait_and_snapshot, 20},
            %Terminal.KeyEvent{code: {:char, "k"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot1,
        """
        ┌───────────────┐--------
        │-Item 1--------│--------
        │ Multiple      │--------
        │ lines         │--------
        │ item          │--------
        │-Item 3--------│--------
        │Selected: item2│--------
        └───────────────┘--------
        -------------------------
        -------------------------\
        """
      )

      assert_content(
        snapshot2,
        """
        ┌───────────────┐--------
        │ Item 1        │--------
        │-Multiple------│--------
        │-lines---------│--------
        │-item----------│--------
        │-Item 3--------│--------
        │Selected: item1│--------
        └───────────────┘--------
        -------------------------
        -------------------------\
        """
      )
    end
  end

  test "auto scrolling" do
    [snapshot1, snapshot2, snapshot3] =
      Test.render({__MODULE__.List, style: [height: 6]},
        terminal_size: {25, 10},
        events: [
          {:wait_and_snapshot, 10},
          # Move to down Item 4 which is out of view
          # Auto scroll down
          %Terminal.KeyEvent{code: {:char, "j"}},
          %Terminal.KeyEvent{code: {:char, "j"}},
          %Terminal.KeyEvent{code: {:char, "j"}},
          {:wait_and_snapshot, 10},
          # Move to up Item 1 which is out of view
          # Auto scroll up
          %Terminal.KeyEvent{code: {:char, "k"}},
          %Terminal.KeyEvent{code: {:char, "k"}},
          %Terminal.KeyEvent{code: {:char, "k"}},
          {:wait_and_snapshot, 10}
        ]
      )

    assert_content(
      snapshot1,
      """
      ┌───────────────┐--------
      │ Item 1       ▐│--------
      │-Item 2-------▐│--------
      │-Item 3-------││--------
      │Selected: item1│--------
      └───────────────┘--------
      -------------------------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot2,
      """
      ┌───────────────┐--------
      │-Item 2-------▐│--------
      │-Item 3-------▐│--------
      │ Item 4       ││--------
      │Selected: item4│--------
      └───────────────┘--------
      -------------------------
      -------------------------
      -------------------------
      -------------------------\
      """
    )

    assert_content(
      snapshot3,
      """
      ┌───────────────┐--------
      │ Item 1       ▐│--------
      │-Item 2-------▐│--------
      │-Item 3-------││--------
      │Selected: item1│--------
      └───────────────┘--------
      -------------------------
      -------------------------
      -------------------------
      -------------------------\
      """
    )
  end

  test "renders empty placeholder when no items" do
    [snapshot] =
      Test.render({Orange.Component.List, items: [], empty_placeholder: "No items available"},
        terminal_size: {25, 5},
        events: [{:wait_and_snapshot, 10}]
      )

    assert_content(
      snapshot,
      """
      -No items available------
      -------------------------
      -------------------------
      -------------------------
      -------------------------\
      """
    )
  end

  test "disabled list ignores keyboard events" do
    [snapshot] =
      Test.render({__MODULE__.List, disabled: true},
        terminal_size: {25, 10},
        events: [
          # This should be ignored
          %Terminal.KeyEvent{code: {:char, "j"}},
          {:wait_and_snapshot, 10}
        ]
      )

    assert_content(
      snapshot,
      """
      ┌───────────────┐--------
      │ Item 1        │--------
      │-Item 2--------│--------
      │-Item 3--------│--------
      │-Item 4--------│--------
      │-Item 5--------│--------
      │Selected: item1│--------
      └───────────────┘--------
      -------------------------
      -------------------------\
      """
    )
  end

  describe "style" do
    test "list style" do
      [snapshot] =
        Test.render(
          {
            Orange.Component.List,
            items: [
              %{key: :item1, item: "Item 1", height: 1},
              %{key: :item2, item: "Item 2", height: 1}
            ],
            selected_item: :item1,
            style: [border: true, background_color: :blue, width: 15]
          },
          terminal_size: {20, 5},
          events: [{:wait_and_snapshot, 10}]
        )

      assert_content(
        snapshot,
        """
        ┌─────────────┐-----
        │ Item 1      │-----
        │ Item 2      │-----
        └─────────────┘-----
        --------------------\
        """
      )

      Enum.each([0, 2, 3], fn y ->
        Enum.each(0..14, fn x ->
          assert_background_color(snapshot, x, y, :blue)
        end)
      end)
    end

    test "item style" do
      [snapshot] =
        Test.render(
          {
            Orange.Component.List,
            items: [
              %{key: :item1, item: "Item 1", height: 1},
              %{key: :item2, item: "Item 2", height: 1}
            ],
            selected_item: :item1,
            item_style: fn
              true = _is_selected -> [background_color: :yellow]
              false -> [background_color: :blue]
            end
          },
          terminal_size: {20, 5},
          events: [{:wait_and_snapshot, 10}]
        )

      assert_content(
        snapshot,
        """
         Item 1 ------------
         Item 2 ------------
        --------------------
        --------------------
        --------------------\
        """
      )

      Enum.each(0..7, fn x ->
        assert_background_color(snapshot, x, 0, :yellow)
      end)

      Enum.each(0..7, fn x ->
        assert_background_color(snapshot, x, 1, :blue)
      end)
    end
  end

  test "show_scroll_bar controls whether to render the scroll bar" do
    items = [
      %{key: :item1, item: "Item 1", height: 1},
      %{key: :item2, item: "Item 2", height: 1},
      %{key: :item3, item: "Item 3", height: 1},
      %{key: :item4, item: "Item 4", height: 1},
      %{key: :item5, item: "Item 5", height: 1}
    ]

    [snapshot] =
      Test.render(
        {
          Orange.Component.List,
          items: items,
          selected_item: :item2,
          style: [height: 3],
          scroll_offset: 1,
          show_scroll_bar: false
        },
        terminal_size: {20, 3},
        events: [{:wait_and_snapshot, 10}]
      )

    assert_content(
      snapshot,
      """
      -Item 1-------------
       Item 2 ------------
      -Item 3-------------\
      """
    )
  end

  test "automatically scrolls the selecting item into view during the initial render" do
    [snapshot] =
      Test.render(
        {
          __MODULE__.List,
          selected_item: :item4, style: [height: 6]
        },
        terminal_size: {20, 10},
        events: [{:wait_and_snapshot, 20}]
      )

    assert_content(
      snapshot,
      """
      ┌───────────────┐---
      │-Item 2-------▐│---
      │-Item 3-------▐│---
      │ Item 4       ││---
      │Selected: item4│---
      └───────────────┘---
      --------------------
      --------------------
      --------------------
      --------------------\
      """
    )
  end

  defmodule List do
    @behaviour Orange.Component

    import Orange.Macro
    alias Orange.{Terminal, Component}

    @impl true
    def init(attrs),
      do: %{
        state: %{selected_item: Keyword.get(attrs, :selected_item, :item1), scroll_offset: 0},
        events_subscription: true
      }

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
    def render(state, attrs, update) do
      items =
        Keyword.get(
          attrs,
          :items,
          for i <- 1..5 do
            %{key: String.to_atom("item#{i}"), item: "Item #{i}", height: 1}
          end
        )

      style =
        Keyword.merge([flex_direction: :column, border: true, min_height: 0], attrs[:style] || [])

      rect style: style do
        {
          Component.List,
          items: items,
          selected_item: state.selected_item,
          on_selected_item_change: fn key ->
            update.(fn state -> %{state | selected_item: key} end)
          end,
          scroll_offset: state.scroll_offset,
          on_scroll_offset_change: fn offset ->
            update.(fn state -> %{state | scroll_offset: offset} end)
          end,
          empty_placeholder: "No items available",
          disabled: Keyword.get(attrs, :disabled, false),
          style: attrs[:style],
          item_style: attrs[:item_style],
          show_scroll_bar: Keyword.get(attrs, :show_scroll_bar, true)
        }

        rect do
          "Selected: #{state.selected_item}"
        end
      end
    end
  end
end
