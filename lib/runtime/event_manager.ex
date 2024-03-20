defmodule Orange.Runtime.EventManager do
  @moduledoc false

  alias Orange.{Terminal, Runtime}

  @state __MODULE__.State

  @callback init() :: any()
  @callback subscribe(reference()) :: any()
  @callback unsubscribe(reference()) :: any()
  @callback focus(reference()) :: any()
  @callback unfocus(reference()) :: any()
  @callback start_background_event_poller() :: any()
  @callback dispatch_event(Orange.Terminal.KeyEvent.t()) :: any()

  @behaviour __MODULE__

  def init() do
    :ets.new(@state, [:named_table, :set, :public])
    :ets.insert(@state, {:subscribers, MapSet.new()})
    :ets.insert(@state, {:focus, nil})
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

  def start_background_event_poller() do
    parent = self()
    Task.start(fn -> poll_event(parent) end)
  end

  defp poll_event(parent) do
    event = terminal_impl().poll_event()
    send(parent, {:event, event})
    poll_event(parent)
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

  defp terminal_impl(), do: Application.get_env(:orange, :terminal, Terminal)
end
