# Handle terminal events

Custom components can have local state. To make them becomes interactive, they need to react to terminal events. There are two ways to achieve that:

## Init configuration

In component's init callback, we can return a configuration with `events_subscription: true` to subscribe events for the component.

```elixir
defmodule Example do
  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: nil, events_subscription: true}

  @impl true
  def handle_event(event, state, _attrs) do
    case event do
      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        Orange.stop()
        state

      %Orange.Terminal.KeyEvent{code: {:char, char}} ->
        IO.puts("Key pressed: #{char}")
        state

      _ ->
        state
    end
  end

  @impl true
  def render(state, _attrs, _update) do
    rect style: [width: 20, height: 20] do
      "Hello"
    end
  end
end

# Start the application. To quit, press 'q'.
Orange.start(Example)
```

Your component can handle events with the `handle_event/3` callback and returns the updated state.

## Orange.subscribe/1

If you want to manually subscribe, use `Orange.subscribe/1`.

```elixir
defmodule Example do
  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: nil}

  @impl true
  def after_mount(_state, _attrs, _update) do
    Orange.subscribe(:root)
  end

  @impl true
  def handle_event(event, state, _attrs) do
    case event do
      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        Orange.stop()
        state

      _ ->
        state
    end
  end

  @impl true
  def render(state, _attrs, _update) do
    rect style: [width: 20, height: 20] do
      "Hello"
    end
  end
end

# Start the application. To quit, press 'q'.
Orange.start({Example, id: :root})
```

## Remove events subscription

To unsubcribe for events, use `Orange.unsubcribe/1`.

## Component focus mode

There are certain cases that you only want one component to receive events and prevent other components. Look at the above example, an input component should receive all the events and prevent users from quitting the application when hitting "q". To do that, we can set a component as focused with `Orange.focus/1`. Only the focused component can receive terminal events. To remove the focus status, use `Orange.unfocus/1`.

# Supported events

- Keyboard events: see `Orange.Terminal.KeyEvent` for more details
- Terminal resize event: see `Orange.Terminal.ResizeEvent` for more details
