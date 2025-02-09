defmodule Orange.Component.TabBarTest do
  use ExUnit.Case
  import Mox

  alias Orange.Renderer.Buffer
  alias Orange.{Terminal, RuntimeTestHelper}
  alias Orange.RendererTestHelper

  setup_all do
    Mox.defmock(Orange.MockTerminal, for: Terminal)
    Application.put_env(:orange, :terminal, Orange.MockTerminal)

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  test "no tabs" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 5}
    )

    buffer =
      RuntimeTestHelper.dry_render_once({Orange.Component.TabBar, tabs: [], active_tab: :foo})

    assert Buffer.to_string(buffer) === """
           --------------------
           --------------------
           --------------------
           --------------------
           --------------------\
           """
  end

  test "one tab" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 5}
    )

    buffer =
      RuntimeTestHelper.dry_render_once(
        {Orange.Component.TabBar, tabs: [%{id: :foo, name: "Foo"}], active_tab: :foo}
      )

    assert Buffer.to_string(buffer) === """
            Foo 🭬--------------
           --------------------
           --------------------
           --------------------
           --------------------\
           """
  end

  test "with active tab" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 5}
    )

    buffer =
      RuntimeTestHelper.dry_render_once(
        {Orange.Component.TabBar,
         tabs: [%{id: :foo, name: "Foo"}, %{id: :bar, name: "Bar"}, %{id: :baz, name: "Baz"}],
         active_tab: :bar,
         active_color: :yellow}
      )

    Enum.each(6..10, fn x ->
      assert RendererTestHelper.get_background_color(buffer, x, 0) == :yellow
    end)

    assert RendererTestHelper.get_color(buffer, 5, 0) == :yellow
    assert RendererTestHelper.get_color(buffer, 11, 0) == :yellow

    assert Buffer.to_string(buffer) === """
           -Foo-🭨 Bar 🭬-Baz-🯛--
           --------------------
           --------------------
           --------------------
           --------------------\
           """
  end

  defmodule TabBar do
    @behaviour Orange.Component

    import Orange.Macro
    alias Orange.Component

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, attrs, _update) do
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
