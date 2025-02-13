defmodule Orange.Component.TabBarTest do
  use ExUnit.Case

  import Orange.Test.Assertions

  alias Orange.Test

  test "no tabs" do
    snapshot =
      Test.render_once({Orange.Component.TabBar, tabs: [], active_tab: :foo},
        terminal_size: {20, 5}
      )

    assert_content(
      snapshot,
      """
      --------------------
      --------------------
      --------------------
      --------------------
      --------------------\
      """
    )
  end

  test "one tab" do
    snapshot =
      Test.render_once(
        {Orange.Component.TabBar, tabs: [%{id: :foo, name: "Foo"}], active_tab: :foo},
        terminal_size: {20, 5}
      )

    assert_content(
      snapshot,
      """
       Foo 🭬--------------
      --------------------
      --------------------
      --------------------
      --------------------\
      """
    )
  end

  test "with active tab" do
    snapshot =
      Test.render_once(
        {
          Orange.Component.TabBar,
          tabs: [%{id: :foo, name: "Foo"}, %{id: :bar, name: "Bar"}, %{id: :baz, name: "Baz"}],
          active_tab: :bar,
          active_color: :yellow
        },
        terminal_size: {20, 5}
      )

    Enum.each(6..10, fn x ->
      assert_background_color(snapshot, x, 0, :yellow)
    end)

    assert_color(snapshot, 5, 0, :yellow)
    assert_color(snapshot, 11, 0, :yellow)

    assert_content(
      snapshot,
      """
      -Foo-🭨 Bar 🭬-Baz-🯛--
      --------------------
      --------------------
      --------------------
      --------------------\
      """
    )
  end

  defmodule TabBar do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, _attrs, _update) do
      tabs = []

      rect style: [padding: 1] do
        {
          Orange.Component.TabBar,
          tabs: tabs, active_tab: :foo, active_color: :yellow
        }
      end
    end
  end
end
