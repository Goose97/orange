defmodule Orange.Runtime.RenderLoop do
  use GenServer

  alias Orange.{Span, Line, Rect, CustomComponent, Renderer, Terminal, Runtime}

  def child_spec([root]) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, root, [name: __MODULE__]]}
    }
  end

  @impl true
  def init(root) do
    Runtime.ComponentRegistry.init()

    terminal_impl().enter_alternate_screen()
    terminal_impl().enable_raw_mode()
    terminal_impl().hide_cursor()

    state = %{
      root: normalize_custom_component(root),
      terminal_size: terminal_impl().terminal_size(),
      previous_tree: nil,
      previous_buffer: nil
    }

    {:ok, state, {:continue, :tick}}
  end

  defp normalize_custom_component(root) do
    case root do
      module when is_atom(module) -> %CustomComponent{module: module}
      {module, attrs} when is_atom(module) -> %CustomComponent{module: module, attributes: attrs}
      _ -> root
    end
  end

  defp terminal_impl(), do: Application.get_env(:orange, :terminal, Terminal)

  defp event_manager_impl(),
    do: Application.get_env(:orange, :event_manager, Runtime.EventManager)

  @impl true
  def handle_continue(:tick, state) do
    state = render_tick(state)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_state, ref, callback_or_value}, state) do
    process_update(ref, callback_or_value)
    {:noreply, state}
  end

  defp process_update(ref, callback_or_value) do
    %{state: component_state} = Runtime.ComponentRegistry.get(ref)

    new_component_state =
      if is_function(callback_or_value, 1),
        do: callback_or_value.(component_state),
        else: callback_or_value

    version = Runtime.ComponentRegistry.update_state(ref, new_component_state)

    # We perform re-render asynchronously. This way we can potentially batch
    # multiple state updates and avoid redundant re-renders
    send(self(), {:state_updated, version})
  end

  @impl true
  def handle_info({:event, event}, state) do
    event_manager_impl().dispatch_event(event)
    state = render_tick(state)

    {:noreply, state}
  end

  @impl true
  def handle_info({:state_updated, version}, state) do
    latest_version = Runtime.ComponentRegistry.get_state_version()
    state = if version == latest_version, do: render_tick(state), else: state

    {:noreply, state}
  end

  def get_component_tree() do
    Process.get({__MODULE__, :component_tree})
  end

  defp render_tick(state) do
    {current_tree, mounting_components, unmounting_components} =
      to_component_tree(state.root, state.previous_tree)

    Process.put({__MODULE__, :component_tree}, current_tree)

    {width, height} = state.terminal_size

    current_buffer =
      to_render_tree(current_tree)
      |> Renderer.render(%{width: width, height: height})

    terminal_impl().draw(current_buffer, state.previous_buffer)

    after_mount(mounting_components)
    after_unmount(unmounting_components)

    %{state | previous_tree: current_tree, previous_buffer: current_buffer}
  end

  # We need to expand all custom components to their rendered children. Also, we need to
  # persist the state of the custom components between renders.
  # The algorithm is as follows:
  # 1. Walk the current tree and compare with the corresponding node in the previous tree (use expend_with_prev/2). Except for the first render, when the previous tree is not available, use expand_new/1
  # 2. Compare the current node to the previous node:
  #   a. If the nodes are of the same type, diff their children and expand them recursively. If the current
  #    node is a custom component, copy the state from the previous node.
  #   b. If the nodes are of different types, expand the current node as new
  defp to_component_tree(component, previous_tree) do
    Process.put({__MODULE__, :mounting_components}, [])
    Process.put({__MODULE__, :unmounting_components}, [])

    expanded_tree =
      if previous_tree,
        do: expand_with_prev(component, previous_tree),
        else: expand_new(component)

    mounting_components = Process.get({__MODULE__, :mounting_components})
    unmounting_components = Process.get({__MODULE__, :unmounting_components})

    {expanded_tree, mounting_components, unmounting_components}
  end

  defp expand_new(%Span{} = component), do: component
  defp expand_new(%Line{} = component), do: component

  defp expand_new(%Rect{} = component),
    do: %{component | children: Enum.map(component.children, &expand_new/1)}

  # Custom components
  defp expand_new(%CustomComponent{module: module, attributes: attrs} = component) do
    result = apply(module, :init, [attrs])
    ref = Runtime.ComponentRegistry.register(result.state, attrs, module)

    content =
      apply(module, :render, [result.state, attrs, &update_callback(ref, &1)])
      |> normalize_custom_component()
      |> expand_new()

    %{component | children: [content], ref: ref}
    |> tap(fn component ->
      opts = [events_subscription: Map.get(result, :events_subscription, false)]
      add_to_mounting_list(component, opts)
    end)
  end

  defp add_to_mounting_list(component, opts) do
    mounted = Process.get({__MODULE__, :mounting_components})
    Process.put({__MODULE__, :mounting_components}, [{component, opts} | mounted])
  end

  defp add_to_unmounting_list(%CustomComponent{} = component) do
    mounted = Process.get({__MODULE__, :unmounting_components})
    Process.put({__MODULE__, :unmounting_components}, [component | mounted])
  end

  defp add_to_unmounting_list(_component), do: :noop

  defp expand_with_prev(%Span{} = component, _previous_tree), do: component
  defp expand_with_prev(%Line{} = component, _previous_tree), do: component

  defp expand_with_prev(%Rect{} = component, %Rect{} = previous_tree) do
    diffs = Runtime.ChildrenDiff.run(component.children, previous_tree.children)

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
    %{state: state} = Runtime.ComponentRegistry.get(previous_component.ref)
    Runtime.ComponentRegistry.update_attributes(previous_component.ref, attrs)

    current_child =
      apply(module, :render, [
        state,
        attrs,
        &update_callback(previous_component.ref, &1)
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

  defp update_callback(component_ref, callback_or_value) do
    # Optimize for the common case where update_callback is called from the render loop
    # In this case, we can avoid the cast and directly call process_update to avoid message passing
    # and the overhead of the GenServer. This is significant if the state is really big
    render_loop_pid = GenServer.whereis(__MODULE__)

    if self() == render_loop_pid do
      process_update(component_ref, callback_or_value)
    else
      GenServer.cast(
        __MODULE__,
        {:update_state, component_ref, callback_or_value}
      )
    end
  end

  defp after_mount(components) do
    Enum.each(components, fn {%CustomComponent{ref: ref}, opts} ->
      if opts[:events_subscription], do: event_manager_impl().subscribe(ref)

      %{state: state, attributes: attrs, module: module} = Runtime.ComponentRegistry.get(ref)

      if function_exported?(module, :after_mount, 3) do
        apply(module, :after_mount, [state, attrs, &update_callback(ref, &1)])
      end
    end)
  end

  defp after_unmount(components) do
    Enum.each(components, fn %CustomComponent{ref: ref} ->
      event_manager_impl().unsubscribe(ref)

      %{state: state, attributes: attrs, module: module} = Runtime.ComponentRegistry.get(ref)

      if function_exported?(module, :after_unmount, 3) do
        apply(module, :after_unmount, [state, attrs, &update_callback(ref, &1)])
      end
    end)
  end
end
