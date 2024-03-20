defmodule Orange do
  @doc """
  Start the runtime and render the UI root.

  The root component must be a custom component.
  """
  defdelegate start(element), to: Orange.Runtime

  @doc """
  Stop the runtime and exit the application
  """
  defdelegate stop(), to: Orange.Runtime

  @doc """
  Subscribe to the event manager.

  Subscribed components will receive terminal events. To unsubscribe, use `unsubscribe/1`.
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
end
