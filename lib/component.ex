defmodule Orange.Component do
  @moduledoc """
  A component is a self-contained UI element that can be reused across the application
  """

  @type ui_element :: Orange.Rect.t() | Orange.Line.t() | Orange.Span.t()
  @type state :: map
  @type event :: Orange.Terminal.KeyEvent.t()
  @type update_callback :: (state -> state) | state

  @callback init(attributes :: map()) :: %{state: state, subscribe_events: boolean()}
  @callback render(state, attributes :: map(), update_callback) :: ui_element
  @callback handle_event(event, state, attributes :: map()) :: state
  @callback after_mount(state, attributes :: map(), update_callback) :: any()
  @callback after_unmount(state, attributes :: map(), update_callback) :: any()

  @optional_callbacks [handle_event: 3, after_mount: 3, after_unmount: 3]
end
