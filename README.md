Orange is a framework to build TUI (terminal UI) applications in Elixir. Its high-level features are:

  * A DSL to describe UI component. The syntax is inspired by React. For example, an snippet like this:

    ```elixir
    rect style: [border: true, padding: {0, 1}, height: 10, width: 20] do
      span style: [color: :red] do
        "Hello"
      end

      span do
        "World"
      end
    end
    ```

    will render this:

    ![Rendered result](https://github.com/Goose97/orange/blob/main/.github/assets/example_syntax.png)

  * Support handling terminal events: currently, only keyboard events are supported.

  * Support custom components: you can create component from builtin primitives like rect, line, span. Custom components can encapsulate state and logic.

  * A collection of UI components: Input, VerticalScrollRect, ...

## Examples

First, we need to create a root component:

```elixir
defmodule Counter.App do
  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  # Each component can have an internal state
  # Also, a component can subscribe to receive terminal events
  def init(_attrs), do: %{state: %{count: 0}, events_subscription: true}

  @impl true
  def handle_event(event, state, _attrs) do
    case event do
      # Arrow up to increase counter
      %Orange.Terminal.KeyEvent{code: :up} ->
        %{state | count: state.count + 1}

      # Arrow down to decrease counter
      %Orange.Terminal.KeyEvent{code: :down} ->
        %{state | count: state.count - 1}

      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        # Quit the application
        Orange.stop()
        state

      _ ->
        state
    end
  end

  @impl true
  def render(state, _attrs, _update) do
    rect style: [border: true, padding: 1] do
      "Counter: #{state.count}"
    end
  end
end
```

Then start the application:

```elixir
Orange.start(Counter.App)
```

For more examples, see [here](/examples).
