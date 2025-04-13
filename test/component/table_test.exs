defmodule Orange.Component.TableTest do
  use ExUnit.Case

  import Orange.Macro
  import Orange.Test.Assertions

  alias Orange.{Terminal, Test}

  test "renders basic table with headers and rows" do
    columns = [
      %{id: :name, name: "Name", sort_key: "n"},
      %{id: :age, name: "Age", sort_key: "a"}
    ]

    rows = [
      {:row1, ["Alice", "30"]},
      {:row2, ["Bob", "25"]},
      {:row3, ["Charlie", "35"]}
    ]

    [snapshot] =
      Test.render(
        {Orange.Component.Table, columns: columns, rows: rows, selected_row_index: 0},
        terminal_size: {30, 10},
        events: [{:wait_and_snapshot, 10}]
      )

    assert_content(
      snapshot,
      """
      ╭────────────────────────────╮
      │-Name-(n)----Age-(a)--------│
      ├────────────────────────────┤
      │ Alice       30        -----│
      │-Bob---------25-------------│
      │-Charlie-----35-------------│
      │----------------------------│
      │----------------------------│
      │----------------------------│
      ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 3 >🭹╯\
      """
    )
  end

  describe "renders sort indicator" do
    test "sort direction :desc" do
      columns = [
        %{id: :name, name: "Name", sort_key: "n"},
        %{id: :age, name: "Age", sort_key: "a"}
      ]

      rows = [
        {:row1, ["Alice", "30"]},
        {:row2, ["Bob", "25"]},
        {:row3, ["Charlie", "35"]}
      ]

      [snapshot] =
        Test.render(
          {
            Orange.Component.Table,
            columns: columns, rows: rows, selected_row_index: 0, sort_column: {:name, :desc}
          },
          terminal_size: {30, 10},
          events: [{:wait_and_snapshot, 10}]
        )

      assert_content(
        snapshot,
        """
        ╭────────────────────────────╮
        │-Name-(n) ▼--Age-(a)--------│
        ├────────────────────────────┤
        │ Charlie     35        -----│
        │-Bob---------25-------------│
        │-Alice-------30-------------│
        │----------------------------│
        │----------------------------│
        │----------------------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 3 >🭹╯\
        """
      )
    end

    test "sort direction :asc" do
      columns = [
        %{id: :name, name: "Name", sort_key: "n"},
        %{id: :age, name: "Age", sort_key: "a"}
      ]

      rows = [
        {:row1, ["Alice", "30"]},
        {:row2, ["Bob", "25"]},
        {:row3, ["Charlie", "35"]}
      ]

      [snapshot] =
        Test.render(
          {
            Orange.Component.Table,
            columns: columns, rows: rows, selected_row_index: 0, sort_column: {:name, :asc}
          },
          terminal_size: {30, 10},
          events: [{:wait_and_snapshot, 10}]
        )

      assert_content(
        snapshot,
        """
        ╭────────────────────────────╮
        │-Name-(n) ▲--Age-(a)--------│
        ├────────────────────────────┤
        │ Alice       30        -----│
        │-Bob---------25-------------│
        │-Charlie-----35-------------│
        │----------------------------│
        │----------------------------│
        │----------------------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 3 >🭹╯\
        """
      )
    end
  end

  test "renders with custom footer" do
    columns = [
      %{id: :name, name: "Name"},
      %{id: :age, name: "Age"}
    ]

    rows = [
      {:row1, ["Alice", "30"]},
      {:row2, ["Bob", "25"]},
      {:row3, ["Charlie", "35"]}
    ]

    [snapshot] =
      Test.render(
        {
          Orange.Component.Table,
          columns: columns,
          rows: rows,
          selected_row_index: 0,
          footer: fn %{current_row: current, total_rows: total} ->
            "Row #{current} of #{total}"
          end
        },
        terminal_size: {30, 10},
        events: [{:wait_and_snapshot, 10}]
      )

    assert_content(
      snapshot,
      """
      ╭────────────────────────────╮
      │-Name-----Age---------------│
      ├────────────────────────────┤
      │ Alice    30  --------------│
      │-Bob------25----------------│
      │-Charlie--35----------------│
      │----------------------------│
      │----------------------------│
      │----------------------------│
      ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹Row 1 of 3🭹╯\
      """
    )
  end

  describe "navigation" do
    test "pressing j/k moves the selection to the next/previous row" do
      [snapshot1, snapshot2] =
        Test.render(__MODULE__.TableWrapper,
          terminal_size: {30, 7},
          events: [
            # Move down
            %Terminal.KeyEvent{code: {:char, "j"}},
            {:wait_and_snapshot, 20},
            # Move back up
            %Terminal.KeyEvent{code: {:char, "k"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot1,
        """
        ╭────────────────────────────╮
        │-Name-(n)----Age-(a)--------│
        ├────────────────────────────┤
        │-Alice-------30-------------│
        │ Bob         25        -----│
        │-Charlie-----35-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 2 of 6 >🭹╯\
        """
      )

      assert_content(
        snapshot2,
        """
        ╭────────────────────────────╮
        │-Name-(n)----Age-(a)--------│
        ├────────────────────────────┤
        │ Alice       30        -----│
        │-Bob---------25-------------│
        │-Charlie-----35-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 6 >🭹╯\
        """
      )
    end

    test "pressing j does NOTHING when at the bottom of the table" do
      [snapshot] =
        Test.render(__MODULE__.TableWrapper,
          terminal_size: {30, 7},
          events: [
            %Terminal.KeyEvent{code: {:char, "j"}},
            %Terminal.KeyEvent{code: {:char, "j"}},
            %Terminal.KeyEvent{code: {:char, "j"}},
            %Terminal.KeyEvent{code: {:char, "j"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot,
        """
        ╭────────────────────────────╮
        │-Name-(n)----Age-(a)--------│
        ├────────────────────────────┤
        │-Alice-------30-------------│
        │-Bob---------25-------------│
        │ Charlie     35        -----│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 3 of 6 >🭹╯\
        """
      )
    end

    test "pressing k does NOTHING when at the top of the table" do
      [snapshot] =
        Test.render(__MODULE__.TableWrapper,
          terminal_size: {30, 7},
          events: [
            %Terminal.KeyEvent{code: {:char, "k"}},
            %Terminal.KeyEvent{code: {:char, "k"}},
            %Terminal.KeyEvent{code: {:char, "k"}},
            %Terminal.KeyEvent{code: {:char, "k"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot,
        """
        ╭────────────────────────────╮
        │-Name-(n)----Age-(a)--------│
        ├────────────────────────────┤
        │ Alice       30        -----│
        │-Bob---------25-------------│
        │-Charlie-----35-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 6 >🭹╯\
        """
      )
    end
  end

  describe "pagination" do
    test "pressing </> navigates to the next/previous page" do
      [snapshot1, snapshot2] =
        Test.render(__MODULE__.TableWrapper,
          terminal_size: {30, 7},
          events: [
            # Next page
            %Terminal.KeyEvent{code: {:char, ">"}},
            {:wait_and_snapshot, 20},
            # Previous page
            %Terminal.KeyEvent{code: {:char, "<"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot1,
        """
        ╭────────────────────────────╮
        │-Name-(n)----Age-(a)--------│
        ├────────────────────────────┤
        │ David       40        -----│
        │-Eve---------28-------------│
        │-Frank-------33-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 4 of 6 >🭹╯\
        """
      )

      assert_content(
        snapshot2,
        """
        ╭────────────────────────────╮
        │-Name-(n)----Age-(a)--------│
        ├────────────────────────────┤
        │ Alice       30        -----│
        │-Bob---------25-------------│
        │-Charlie-----35-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 6 >🭹╯\
        """
      )
    end

    test "pressing > does NOTHING when at the last page" do
      [snapshot] =
        Test.render(__MODULE__.TableWrapper,
          terminal_size: {30, 7},
          events: [
            %Terminal.KeyEvent{code: {:char, ">"}},
            %Terminal.KeyEvent{code: {:char, ">"}},
            %Terminal.KeyEvent{code: {:char, ">"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot,
        """
        ╭────────────────────────────╮
        │-Name-(n)----Age-(a)--------│
        ├────────────────────────────┤
        │ David       40        -----│
        │-Eve---------28-------------│
        │-Frank-------33-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 4 of 6 >🭹╯\
        """
      )
    end

    test "pressing < does NOTHING when at the first page" do
      [snapshot] =
        Test.render(__MODULE__.TableWrapper,
          terminal_size: {30, 7},
          events: [
            %Terminal.KeyEvent{code: {:char, "<"}},
            %Terminal.KeyEvent{code: {:char, "<"}},
            %Terminal.KeyEvent{code: {:char, "<"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot,
        """
        ╭────────────────────────────╮
        │-Name-(n)----Age-(a)--------│
        ├────────────────────────────┤
        │ Alice       30        -----│
        │-Bob---------25-------------│
        │-Charlie-----35-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 6 >🭹╯\
        """
      )
    end
  end

  describe "sorting" do
    test "pressing sort key changes sort column and direction" do
      [snapshot1, snapshot2] =
        Test.render(
          rect style: [width: "100%", height: "100%"] do
            Orange.Component.TableTest.TableWrapper
          end,
          terminal_size: {30, 10},
          events: [
            # Sort by name
            %Terminal.KeyEvent{code: {:char, "n"}},
            {:wait_and_snapshot, 20},
            # Toggle sort direction
            %Terminal.KeyEvent{code: {:char, "n"}},
            {:wait_and_snapshot, 20}
          ]
        )

      assert_content(
        snapshot1,
        """
        ╭────────────────────────────╮
        │-Name-(n) ▼--Age-(a)--------│
        ├────────────────────────────┤
        │ Frank       33        -----│
        │-Eve---------28-------------│
        │-David-------40-------------│
        │-Charlie-----35-------------│
        │-Bob---------25-------------│
        │-Alice-------30-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 6 >🭹╯\
        """
      )

      assert_content(
        snapshot2,
        """
        ╭────────────────────────────╮
        │-Name-(n) ▲--Age-(a)--------│
        ├────────────────────────────┤
        │ Alice       30        -----│
        │-Bob---------25-------------│
        │-Charlie-----35-------------│
        │-David-------40-------------│
        │-Eve---------28-------------│
        │-Frank-------33-------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 6 >🭹╯\
        """
      )
    end
  end

  test "custom actions" do
    Test.render(
      {
        Orange.Component.Table,
        columns: [%{id: :name, name: "Name"}],
        rows: [{:row1, ["Alice"]}, {:row2, ["Bob"]}],
        selected_row_index: 1,
        actions: [
          {:enter,
           fn row_key ->
             :persistent_term.put({__MODULE__, :select_row_test}, row_key)
           end}
        ]
      },
      terminal_size: {30, 10},
      events: [
        # Move down and select
        %Terminal.KeyEvent{code: {:char, "j"}},
        %Terminal.KeyEvent{code: :enter}
      ]
    )

    assert :persistent_term.get({__MODULE__, :select_row_test}) == :row2
  end

  describe "horizontal scrolling" do
    test "pressing H/L scrolls horizontally" do
      columns = [
        %{id: :name, name: "Name"},
        %{id: :email, name: "Email Address"},
        %{id: :phone, name: "Phone Number"},
        %{id: :address, name: "Address"}
      ]

      rows = [
        {:row1, ["Alice", "alice@example.com", "123-456-7890", "123 Main St"]},
        {:row2, ["Bob", "bob@example.com", "234-567-8901", "456 Oak Ave"]}
      ]

      [snapshot1, snapshot2, snapshot3] =
        Test.render(
          {
            Orange.Component.Table,
            columns: columns, rows: rows, selected_row_index: 0
          },
          terminal_size: {30, 10},
          events: [
            {:wait_and_snapshot, 20},
            # Scroll right
            %Terminal.KeyEvent{code: {:char, "L"}},
            {:wait_and_snapshot, 20},
            # Scroll left
            %Terminal.KeyEvent{code: {:char, "H"}},
            {:wait_and_snapshot, 20}
          ]
        )

      # Initial view shows first columns
      assert_content(
        snapshot1,
        """
        ╭────────────────────────────╮
        │-Name---Email Address------P│
        ├────────────────────────────┤
        │ Alice  alice@example.com  1│
        │-Bob----bob@example.com----2│
        │----------------------------│
        │----------------------------│
        │----------------------------│
        │----------------------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹──< 1 of 2 >─╯\
        """
      )

      # Scrolled right to see more columns
      assert_content(
        snapshot2,
        """
        ╭────────────────────────────╮
        │-Email Address------Phone Nu│
        ├────────────────────────────┤
        │ alice@example.com  123-456-│
        │-bob@example.com----234-567-│
        │----------------------------│
        │----------------------------│
        │----------------------------│
        │----------------------------│
        ╰────🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹< 1 of 2 >─╯\
        """
      )

      assert_content(
        snapshot3,
        """
        ╭────────────────────────────╮
        │-Name---Email Address------P│
        ├────────────────────────────┤
        │ Alice  alice@example.com  1│
        │-Bob----bob@example.com----2│
        │----------------------------│
        │----------------------------│
        │----------------------------│
        │----------------------------│
        ╰🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹🭹──< 1 of 2 >─╯\
        """
      )
    end
  end

  test "disabled table ignores keyboard events" do
    [snapshot1, snapshot2] =
      Test.render(
        {
          __MODULE__.TableWrapper,
          disabled: true
        },
        terminal_size: {30, 10},
        events: [
          {:wait_and_snapshot, 20},
          # These should be ignored
          %Terminal.KeyEvent{code: {:char, "j"}},
          %Terminal.KeyEvent{code: {:char, "n"}},
          {:wait_and_snapshot, 20}
        ]
      )

    assert Test.Snapshot.content(snapshot1) == Test.Snapshot.content(snapshot2)
  end

  defmodule TableWrapper do
    @behaviour Orange.Component

    alias Orange.Component

    @impl true
    def init(_attrs),
      do: %{
        state: %{
          selected_row_index: 0,
          sort_column: nil,
          current_page: 0
        },
        events_subscription: true
      }

    @impl true
    def render(state, attrs, update) do
      columns = [
        %{id: :name, name: "Name", sort_key: "n"},
        %{id: :age, name: "Age", sort_key: "a"}
      ]

      rows = [
        {:row1, ["Alice", "30"]},
        {:row2, ["Bob", "25"]},
        {:row3, ["Charlie", "35"]},
        {:row4, ["David", "40"]},
        {:row5, ["Eve", "28"]},
        {:row6, ["Frank", "33"]}
      ]

      {
        Component.Table,
        columns: columns,
        rows: rows,
        selected_row_index: state.selected_row_index,
        sort_column: state.sort_column,
        current_page: state.current_page,
        disabled: Keyword.get(attrs, :disabled, false),
        on_selected_row_change: fn index ->
          update.(fn state -> %{state | selected_row_index: index} end)
        end,
        on_row_select: fn row_key ->
          if attrs[:on_row_select], do: attrs[:on_row_select].(row_key)
        end,
        on_sort_change: fn sort_column ->
          update.(fn state -> %{state | sort_column: sort_column} end)
        end,
        on_page_change: fn page ->
          update.(fn state -> %{state | current_page: page, selected_row_index: 0} end)
        end
      }
    end
  end
end
