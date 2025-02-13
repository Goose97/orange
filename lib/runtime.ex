defmodule Orange.Runtime do
  @moduledoc false

  # The runtime module is responsible for rendering the UI components. The runtime consists of multiple
  # components:
  #
  # 1. `Orange.Runtime.RenderLoop`: UI rendering loop, implemented as a GenServer. Re-render is triggered in these cases:
  #   a. Receive events from the event poller
  #   b. Receive state update requests from update callbacks
  # 2. `Orange.Runtime.EventManager`: manages event subscriptions and dispatches events to the subscribed components
  # 3. `Orange.Runtime.EventPoller`: polls for events from the terminal and sends to the render loop

  require Logger

  def start(root) do
    children = [
      event_manager_impl(),
      {__MODULE__.RenderLoop, [root]},
      {event_poller_impl(), [[event_receiver: __MODULE__.RenderLoop]]}
    ]

    Supervisor.start_link(children, strategy: :one_for_all, name: __MODULE__)
  end

  def stop do
    spawn(fn ->
      :ok = Supervisor.stop(__MODULE__)
    end)
  end

  defp event_manager_impl(),
    do: Application.get_env(:orange, :event_manager, __MODULE__.EventManager)

  defp event_poller_impl(),
    do: Application.get_env(:orange, :event_poller, __MODULE__.EventPoller)

  def subscribe(component_id), do: find_component_and_apply(component_id, :subscribe)
  def unsubscribe(component_id), do: find_component_and_apply(component_id, :unsubscribe)
  def focus(component_id), do: find_component_and_apply(component_id, :focus)
  def unfocus(component_id), do: find_component_and_apply(component_id, :unfocus)

  defp find_component_and_apply(component_id, function) do
    case __MODULE__.RenderLoop.component_ref_by_id(component_id) do
      nil ->
        Logger.warning("""
        #{__MODULE__}.#{function}: component not found
        - component_id: #{inspect(component_id)}
        """)

      component_ref when is_reference(component_ref) ->
        apply(event_manager_impl(), function, [component_ref])
    end
  end
end
