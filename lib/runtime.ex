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

  alias Orange.{Span, Line, Rect, CustomComponent, Renderer, Terminal}

  @doc """
  Start the runtime and render the UI root
  """
  def start(root) do
    __MODULE__.ComponentRegistry.init()
    event_manager_impl().init()

    terminal_impl().enter_alternate_screen()
    terminal_impl().enable_raw_mode()
    terminal_impl().hide_cursor()

    terminal_size = terminal_impl().terminal_size()
    root = normalize_custom_component(root)

    event_manager_impl().start_background_event_poller()
    render_loop(root, {nil, nil}, terminal_size: terminal_size)
  end

  defp normalize_custom_component(root) do
    case root do
      module when is_atom(module) -> %CustomComponent{module: module}
      {module, attrs} when is_atom(module) -> %CustomComponent{module: module, attributes: attrs}
      _ -> root
    end
  end

  @doc """
  Stop the runtime and exit the application
  """
  def stop do
    terminal_impl().leave_alternate_screen()
    terminal_impl().disable_raw_mode()
    terminal_impl().show_cursor()
    System.halt(0)
  end

  defp render_loop(root, {previous_tree, previous_buffer}, opts) do
    :persistent_term.put({__MODULE__, :mounting_components}, [])
    :persistent_term.put({__MODULE__, :unmounting_components}, [])

    current_tree = to_component_tree(root, previous_tree)

    :persistent_term.put({__MODULE__, :component_tree}, current_tree)

    {width, height} = opts[:terminal_size]

    current_buffer =
      to_render_tree(current_tree)
      |> Renderer.render(%{width: width, height: height})

    terminal_impl().draw(current_buffer, previous_buffer)

    :persistent_term.get({__MODULE__, :mounting_components})
    |> after_mount()

    :persistent_term.get({__MODULE__, :unmounting_components})
    |> after_unmount()

    # Block waiting for re-rendering triggers:
    # a. Events from the event manager
    # b. State updates from the custom components
    case receive_message() do
      {:event, event} ->
        event_manager_impl().dispatch_event(event)

      :state_updated ->
        :ok
    end

    render_loop(root, {current_tree, current_buffer}, opts)
  end

  defp receive_message() do
    receive do
      {:event, _event} = message ->
        message

      # When receive multiple :state_updated messages, we only need to process the latest one
      {:state_updated, version} ->
        latest_version = __MODULE__.ComponentRegistry.get_state_version()
        if version == latest_version, do: :state_updated, else: receive_message()
    end
  end

  defp terminal_impl(), do: Application.get_env(:orange, :terminal, Terminal)

  defp event_manager_impl(),
    do: Application.get_env(:orange, :event_manager, __MODULE__.EventManager)

  # We need to expand all custom components to their rendered children. Also, we need to
  # persist the state of the custom components between renders.
  # The algorithm is as follows:
  # 1. Walk the current tree and compare with the corresponding node in the previous tree (use expend_with_prev/2). Except for the first render, when the previous tree is not available, use expand_new/1
  # 2. Compare the current node to the previous node:
  #   a. If the nodes are of the same type, diff their children and expand them recursively. If the current
  #    node is a custom component, copy the state from the previous node.
  #   b. If the nodes are of different types, expand the current node as new
  defp to_component_tree(component, previous_tree) do
    if previous_tree, do: expand_with_prev(component, previous_tree), else: expand_new(component)
  end

  defp expand_new(%Span{} = component), do: component
  defp expand_new(%Line{} = component), do: component

  defp expand_new(%Rect{} = component),
    do: %{component | children: Enum.map(component.children, &expand_new/1)}

  # Custom components
  defp expand_new(%CustomComponent{module: module, attributes: attrs} = component) do
    result = apply(module, :init, [attrs])
    ref = __MODULE__.ComponentRegistry.register(result.state, attrs, module)

    runtime_process = self()

    content =
      apply(module, :render, [result.state, attrs, &update_callback(ref, runtime_process, &1)])
      |> normalize_custom_component()
      |> expand_new()

    %{component | children: [content], ref: ref}
    |> tap(fn component ->
      opts = [events_subscription: Map.get(result, :events_subscription, false)]
      add_to_mounting_list(component, opts)
    end)
  end

  defp add_to_mounting_list(component, opts) do
    mounted = :persistent_term.get({__MODULE__, :mounting_components})
    :persistent_term.put({__MODULE__, :mounting_components}, [{component, opts} | mounted])
  end

  defp add_to_unmounting_list(%CustomComponent{} = component) do
    mounted = :persistent_term.get({__MODULE__, :unmounting_components})
    :persistent_term.put({__MODULE__, :unmounting_components}, [component | mounted])
  end

  defp add_to_unmounting_list(_component), do: :noop

  defp expand_with_prev(%Span{} = component, _previous_tree), do: component
  defp expand_with_prev(%Line{} = component, _previous_tree), do: component

  defp expand_with_prev(%Rect{} = component, %Rect{} = previous_tree) do
    diffs = __MODULE__.ChildrenDiff.run(component.children, previous_tree.children)

    new_children =
      Enum.map(diffs, fn
        {:keep, current, previous} ->
          expand_with_prev(current, previous)

        {:new, current} ->
          expand_new(current)

        {:remove, previous} ->
          add_to_unmounting_list(previous)
          nil
      end)
      |> Enum.reject(&is_nil/1)

    %{component | children: new_children}
  end

  defp expand_with_prev(%Rect{} = component, _previous_tree), do: expand_new(component)

  defp expand_with_prev(
         %CustomComponent{module: module, attributes: attrs},
         %CustomComponent{module: module} = previous_component
       ) do
    %{state: state} = __MODULE__.ComponentRegistry.get(previous_component.ref)
    __MODULE__.ComponentRegistry.update_attributes(previous_component.ref, attrs)

    runtime_process = self()

    current_child =
      apply(module, :render, [
        state,
        attrs,
        &update_callback(previous_component.ref, runtime_process, &1)
      ])
      |> normalize_custom_component()

    prev_child = hd(previous_component.children)

    %{previous_component | children: [expand_with_prev(current_child, prev_child)]}
  end

  defp expand_with_prev(%CustomComponent{} = component, _previous_tree),
    do: expand_new(component)

  defp to_render_tree(component) do
    case component do
      %Rect{} -> %{component | children: Enum.map(component.children, &to_render_tree/1)}
      %Line{} -> component
      %Span{} -> component
      %CustomComponent{} -> hd(component.children) |> to_render_tree()
    end
  end

  defp update_callback(component_ref, runtime_process, callback_or_value) do
    %{state: state} = __MODULE__.ComponentRegistry.get(component_ref)

    new_state =
      if is_function(callback_or_value, 1),
        do: callback_or_value.(state),
        else: callback_or_value

    version = __MODULE__.ComponentRegistry.update_state(component_ref, new_state)

    # We may invoke callback in another process, so we need to specify runtime process explicitly
    # instead of using self
    send(runtime_process, {:state_updated, version})
  end

  defp after_mount(components) do
    Enum.each(components, fn {%CustomComponent{ref: ref}, opts} ->
      if opts[:events_subscription], do: event_manager_impl().subscribe(ref)

      %{state: state, attributes: attrs, module: module} = __MODULE__.ComponentRegistry.get(ref)

      if function_exported?(module, :after_mount, 3) do
        runtime_process = self()
        apply(module, :after_mount, [state, attrs, &update_callback(ref, runtime_process, &1)])
      end
    end)
  end

  defp after_unmount(components) do
    Enum.each(components, fn %CustomComponent{ref: ref} ->
      event_manager_impl().unsubscribe(ref)

      %{state: state, attributes: attrs, module: module} = __MODULE__.ComponentRegistry.get(ref)

      if function_exported?(module, :after_unmount, 3) do
        runtime_process = self()
        apply(module, :after_unmount, [state, attrs, &update_callback(ref, runtime_process, &1)])
      end
    end)
  end

  def subscribe(component_id), do: find_component_and_apply!(component_id, :subscribe)
  def unsubscribe(component_id), do: find_component_and_apply!(component_id, :unsubscribe)
  def focus(component_id), do: find_component_and_apply!(component_id, :focus)
  def unfocus(component_id), do: find_component_and_apply!(component_id, :unfocus)

  defp find_component_and_apply!(component_id, function) do
    component_tree = :persistent_term.get({__MODULE__, :component_tree})

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
