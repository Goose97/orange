defmodule Orange do
  @moduledoc """
  Terminal UI framework for Elixir.

  A framework empowering developers to build complex terminal UI applications. Orange provides a declarative way to build UI components and manage terminal events. Orange offers stateful components which can encapsulate local state and logics, allows you to split your application into discrete sub-components. For example, here is a panel displays a random numbers every 1 second:
      defmodule Panel do
        @behaviour Orange.Component

        import Orange.Macro

        @impl true
        def init(_attrs), do: %{state: 0, events_subscription: true}

        @impl true
        def after_mount(_state, _attrs, update) do
          spawn_link(fn -> random_number(update) end)
        end

        defp random_number(update) do
          number = :rand.uniform(100)
          update.(number)
          Process.sleep(1000)
          random_number(update)
        end

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
        def render(state, _attrs, _update) do
          rect style: [width: 25, height: 10, border: true] do
            rect do
              "Random number: \#{state}"
            end
          end
        end
      end

      # Start the application. To quit, press 'q'.
      Orange.start(Panel)

  ![rendered result](assets/random-panel-example.gif)
  """

  @doc """
  Start the runtime and render the UI root.

  The root component must be a custom component.
  """
  def start(element) do
    {:ok, pid} = Orange.Runtime.start(element)
    ref = Process.monitor(pid)

    # Wait for the runtime to stop with `stop/0`
    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    end
  end

  @doc """
  Stop the runtime
  """
  defdelegate stop(), to: Orange.Runtime

  @doc """
  Subscribe to the event manager.

  Subscribed components will receive terminal events. To unsubscribe, use `unsubscribe/1`.

  ## Examples

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
        def render(_state, _attrs, _update) do
          rect do
            "Hello"
          end
        end
      end

      Orange.start({Example, id: :root})
  """
  defdelegate subscribe(component_id), to: Orange.Runtime

  @doc """
  Unsubscribe to the event manager.
  """
  defdelegate unsubscribe(component_id), to: Orange.Runtime

  @doc """
  Focus a component by component_id.

  There can be only one focused component at a time. If a component is focused, it will receive all the events and prevent other components from receiving them. This is useful when you want a component to intercept all terminal events, for example, an input.
  """
  defdelegate focus(component_id), to: Orange.Runtime

  @doc """
  Unfocus a component by component_id.
  """
  defdelegate unfocus(component_id), to: Orange.Runtime

  @doc """
  Get the layout size of an element by component_id.

  Contrary to the `subscribe/1`, `unsubscribe/1`, `focus/1` and `unfocus/1` functions, which can only
  applied to custom components, this function can be only applied on primitive components, e.g. rect.

  This function returns the size of the component rendered in the terminal. It is useful when you want to
  know the size of a component before rendering it, e.g. making dynamic layout.

  > #### Note {: .info}
  >
  > During the first render, this function will return `nil` because the layout information is not available yet.

  ## Example

      iex> Orange.get_layout_size(Orange.rect(id: :my_rect))
      %{width: 10, height: 10}
  """
  defdelegate get_layout_size(component_id), to: Orange.Runtime
end
