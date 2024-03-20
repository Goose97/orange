defmodule Orange.Runtime do
  # TODO
  # 1. Handle errors in the handle_event callback
  # 2. Improve UX of error logging

  @moduledoc """
  The runtime module is responsible for rendering the UI components. Its major responsibilities are:
  1. Run the render loop to keep rendering the UI at intervals.
  2. Keep track of the state of the UI components.
  3. Dispatch events to the appropriate UI components.
  """

  alias Orange.{Span, Line, Rect, CustomComponent, Terminal}

  @doc """
  Start the runtime and render the UI root
  """
  def start(root) do
    children = [
      event_manager_impl(),
      {event_poller_impl(), [[event_receiver: __MODULE__.RenderLoop]]},
      {__MODULE__.RenderLoop, [root]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  @doc """
  Stop the runtime and exit the application
  """
  def stop do
    terminal_impl().leave_alternate_screen()
    terminal_impl().disable_raw_mode()
    terminal_impl().show_cursor()
    Supervisor.stop(__MODULE__)
  end

  defp terminal_impl(), do: Application.get_env(:orange, :terminal, Terminal)

  defp event_manager_impl(),
    do: Application.get_env(:orange, :event_manager, __MODULE__.EventManager)

  defp event_poller_impl(),
    do: Application.get_env(:orange, :event_poller, __MODULE__.EventPoller)

  def subscribe(component_id), do: find_component_and_apply!(component_id, :subscribe)
  def unsubscribe(component_id), do: find_component_and_apply!(component_id, :unsubscribe)
  def focus(component_id), do: find_component_and_apply!(component_id, :focus)
  def unfocus(component_id), do: find_component_and_apply!(component_id, :unfocus)

  defp find_component_and_apply!(component_id, function) do
    component_tree = __MODULE__.RenderLoop.get_component_tree()

    case find_by_id(component_tree, component_id) do
      nil ->
        raise("""
        #{__MODULE__}.#{function}: component not found
        - component_id: #{inspect(component_id)}
        """)

      %CustomComponent{ref: component_ref} ->
        apply(event_manager_impl(), function, [component_ref])
    end
  end

  defp find_by_id(%Line{}, _component_id), do: nil
  defp find_by_id(%Span{}, _component_id), do: nil

  defp find_by_id(%Rect{children: children}, component_id),
    do: find_in_children(children, component_id)

  defp find_by_id(
         %CustomComponent{children: children, attributes: attributes} = component,
         component_id
       ) do
    if Keyword.has_key?(attributes, :id) && component_id == attributes[:id],
      do: component,
      else: find_in_children(children, component_id)
  end

  defp find_in_children([], _component_id), do: nil

  defp find_in_children([child | remain], component_id) do
    case find_by_id(child, component_id) do
      nil -> find_in_children(remain, component_id)
      component -> component
    end
  end
end
