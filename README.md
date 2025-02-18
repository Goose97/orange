[![Package](https://img.shields.io/badge/-Package-important)](https://hex.pm/packages/orange) [![Documentation](https://img.shields.io/badge/-Documentation-blueviolet)](https://hexdocs.pm/orange)

Orange is a framework to build TUI (terminal UI) applications in Elixir. Its high-level features are:

- A DSL to describe UI component. The syntax is inspired by React. For example, an snippet like this:

  ```elixir
  rect style: [border: true, padding: {0, 1}, height: 10, width: 20] do
    rect style: [color: :red] do
      "Hello"
    end

    rect do
      "World"
    end
  end
  ```

  will render this:

  ![Rendered result](https://github.com/Goose97/orange/blob/main/.github/assets/example_syntax.png)

- Support handling terminal events: currently, only keyboard events are supported.

- Support custom components: you can create component from builtin primitives. Custom components can encapsulate state and logic.

- A collection of UI components: Input, VerticalScrollRect, ...

## Important

When using Orange, it is essential that you prevent the Erlang VM from reading stdin as it can interfere with the terminal events handling logic. You can achieve this via the `-noinput` flag:

```sh
elixir --erl "-noinput" -S mix run --no-halt
```

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
        {:update, %{state | count: state.count + 1}}

      # Arrow down to decrease counter
      %Orange.Terminal.KeyEvent{code: :down} ->
        {:update, %{state | count: state.count - 1}}

      %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
        # Quit the application
        Orange.stop()
        :noop

      _ ->
        :noop
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
