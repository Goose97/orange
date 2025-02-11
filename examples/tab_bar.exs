defmodule TabBar.App do
  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: 0, events_subscription: true}

  @impl true
  def handle_event(event, state, _attrs, _update) do
    case event do
      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        Orange.stop()
        state

      _ ->
        state
    end
  end

  @impl true
  def render(_state, _attrs, _update) do
    tabs = [%{id: :foo, name: "Foo"}, %{id: :bar, name: "Bar"}, %{id: :baz, name: "Baz"}]

    rect style: [padding: 1] do
      {
        Orange.Component.TabBar,
        tabs: tabs, active_tab: :foo, active_color: :yellow
      }
    end
  end
end

# Start the application. To quit, press 'q'.
Orange.start(TabBar.App)
