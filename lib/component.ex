defmodule Orange.Component do
  @moduledoc """
  A behaviour module for implementing custom components.

  A custom component is a self-contained UI component that can be reused across the application. Custom components are composed of other custom or primitive components.

  Custom components can have internal state and receive terminal events to update their state. They also have hooks, which will be trigger at specific points in the component lifecycle, for example, `after_mount/1` and `after_unmount/1`

  ## Examples

  In order to implement a custom component, you need to define a module that implements the `Orange.Component` behaviour. As an example, we will implement a Counter component. We can use up and down button to increase or decrease the counter value.

      defmodule Counter do
        @behaviour Orange.Component

        import Orange.Macro

        @impl true
        def init(_attrs), do: %{state: 0, events_subscription: true}

        @impl true
        def handle_event(event, state, _attrs) do
          case event do
            %Orange.Terminal.KeyEvent{code: :up} ->
              state + 1

            %Orange.Terminal.KeyEvent{code: :down} ->
              state - 1

            _ ->
              state
          end
        end

        @impl true
        def after_mount(state, _attrs, update) do
          # Set counter value to 10 after 5 seconds
          spawn(fn ->
            Process.sleep(5000)
            update.(10)
          end)
        end

        @impl true
        def render(state, attrs, _update) do
          rect style: [width: "100%", height: "1fr", border: attrs[:highlight]] do
            rect do
              "Counter: \#{state}"
            end
          end
        end
      end


  This component can be used as children for other components like this:

      defmodule App do
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

            _ ->
              state
          end
        end

        def render(_state, _attrs, _update) do
          rect style: [width: 20, height: 20, border: true] do
            # No attributes
            Counter

            # Or with attributes
            {Counter, id: :counter, highlight: true}
          end
        end
      end

  ![Rendered result](assets/component-example.gif)

  ## Update callback

  There are two ways to update the component state:

    1. By returning a new state from the `handle_event/3` callback

    2. By using the update callback

  The update callback will be passed to the `render/3` and lifecycle hooks. The update callback can be called with a new state or a function that receives the current state and returns the new state.

      def render(state, attrs, update_callback)
        update_callback.(%{state | counter: state.counter + 1})
        update_callback.(fn state -> %{state | counter: state.counter - 1} end)
      end
  """

  @type ui_element :: Orange.Rect.t()
  @type state :: map
  @type event :: Orange.Terminal.KeyEvent.t()
  @type update_callback :: (state -> state) | state

  @doc """
  Receives the attributes map from parent component and returns the component configuration.

  Configuration keys are:

    * `state` - The initial state of the component

    * `events_subscription` - whether the component should subscribe to terminal events
  """
  @callback init(attributes :: map()) :: %{state: state, events_subscription: boolean()}

  @doc """
  Receives the current state, attributes and [update callback](#module-update-callback) and returns the rendered UI element.

  > #### Info {: .info}
  >
  > This function must either return a single component or nil.
  """
  @callback render(state, attributes :: map(), update_callback) :: ui_element

  @doc """
  Receives the event, current state, and attributes and returns the new state.
  """
  @callback handle_event(event, state, attributes :: map()) :: state

  @doc """
  Lifecycle hook that is called after the component is mounted (first time render to the terminal).
  """
  @callback after_mount(state, attributes :: map(), update_callback) :: any()

  @doc """
  Lifecycle hook that is called after the component is unmounted (remove from the terminal).
  """
  @callback after_unmount(state, attributes :: map(), update_callback) :: any()

  @optional_callbacks [handle_event: 3, after_mount: 3, after_unmount: 3]
end
