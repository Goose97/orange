defmodule Orange.Component.TabBar do
  @moduledoc """
  A tab bar component.

  ## Attributes

    - `:tabs` - A list of tabs. Each tab is a map with the following keys:
      - `:id` - The id of the tab
      - `:name` - The name of the tab
    This attribute is required.

    - `:active_tab` - The id of the active tab. This attribute is required.
    - `:active_color` - The color of the active tab. This attribute is optional. Defaults to `:green`.

  ## Examples

      defmodule Example do
        @behaviour Orange.Component

        import Orange.Macro

        @impl true
        def init(_attrs), do: %{state: nil}

        @impl true
        def render(_state, _attrs, _update) do
          tabs = [%{id: :foo, name: "Foo"}, %{id: :bar, name: "Bar"}, %{id: :baz, name: "Baz"}]

          rect do
            {
              Orange.Component.TabBar,
              tabs: tabs,
              active_tab: :foo,
              active_color: :yellow
            }
          end
        end
      end

    ![rendered result](assets/tab-bar-example.png)
  """

  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_), do: %{state: nil, events_subscription: false}

  defp render_tab_separator(left_tab, nil, attrs) do
    active_tab = attrs[:active_tab]
    {color, text} = if left_tab.id == active_tab, do: {active_color(attrs), "🭬"}, else: {nil, "🯛"}

    rect style: [color: color] do
      text
    end
  end

  defp render_tab_separator(left_tab, right_tab, attrs) do
    active_tab = attrs[:active_tab]

    {color, background_color, text} =
      cond do
        left_tab.id == active_tab -> {active_color(attrs), nil, "🭬"}
        right_tab.id == active_tab -> {active_color(attrs), nil, "🭨"}
        true -> {nil, nil, "🯛"}
      end

    rect style: [color: color, background_color: background_color] do
      text
    end
  end

  @compile {:inline, active_color: 1}
  defp active_color(attrs), do: Keyword.get(attrs, :active_color, :green)

  @impl true
  def render(_state, attrs, _update) do
    tabs =
      attrs[:tabs]
      |> Enum.with_index()
      |> Enum.map(fn {tab, index} ->
        active = tab.id == attrs[:active_tab]
        {color, background_color} = if active, do: {:black, active_color(attrs)}, else: {nil, nil}

        tab_separator =
          render_tab_separator(tab, Enum.at(attrs[:tabs], index + 1), attrs)

        rect do
          rect style: [background_color: background_color, padding: {0, 1}, color: color] do
            tab.name
          end

          tab_separator
        end
      end)

    rect style: [display: :flex] do
      tabs
    end
  end
end
