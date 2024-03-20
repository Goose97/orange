defmodule Orange.Runtime.EventManager do
  @moduledoc false
  # Manage event subscribers. Dispatch events to all subscribers with `dispatch_event/1`

  defmodule Behaviour do
    @callback subscribe(reference()) :: any()
    @callback unsubscribe(reference()) :: any()
    @callback focus(reference()) :: any()
    @callback unfocus(reference()) :: any()
    @callback dispatch_event(Orange.Terminal.KeyEvent.t()) :: any()
  end

  @state __MODULE__.State
  @behaviour __MODULE__.Behaviour

  alias Orange.Runtime

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, []}
    }
  end

  def start() do
    :ets.new(@state, [:named_table, :set, :public])
    :ets.insert(@state, {:subscribers, MapSet.new()})
    :ets.insert(@state, {:focus, nil})

    # Initialize without registering to the supervisor
    :ignore
  end

  def subscribe(component_ref) do
    [{_, subscribers}] = :ets.lookup(@state, :subscribers)
    subscribers = MapSet.put(subscribers, component_ref)

    :ets.update_element(@state, :subscribers, {2, subscribers})
  end

  def unsubscribe(component_ref) do
    [{_, subscribers}] = :ets.lookup(@state, :subscribers)
    subscribers = MapSet.delete(subscribers, component_ref)

    :ets.update_element(@state, :subscribers, {2, subscribers})
  end

  # There can be only one focus component at a time.
  # If a component is focused, it will receive all the events and prevent other components
  # from receiving them.
  def focus(component_ref) do
    :ets.update_element(@state, :focus, {2, component_ref})
  end

  def unfocus(component_ref) do
    [{_, focusing}] = :ets.lookup(@state, :focus)

    if focusing == component_ref,
      do: :ets.update_element(@state, :focus, {2, nil})
  end

  @doc """
  Dispatch event to subscribers
  """
  def dispatch_event(event) do
    receivers = receiving_event_components()

    for component_ref <- receivers do
      %{state: state, attributes: attrs, module: module} =
        Runtime.ComponentRegistry.get(component_ref)

      if function_exported?(module, :handle_event, 3) do
        new_state = apply(module, :handle_event, [event, state, attrs])
        Runtime.ComponentRegistry.update_state(component_ref, new_state)
      end
    end
  end

  defp receiving_event_components() do
    [{_, focusing}] = :ets.lookup(@state, :focus)

    if focusing do
      [focusing]
    else
      [{_, subscribers}] = :ets.lookup(@state, :subscribers)
      MapSet.to_list(subscribers)
    end
  end
end
