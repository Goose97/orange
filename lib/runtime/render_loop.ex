defmodule Orange.Runtime.RenderLoop do
  @moduledoc false

  # Render loop process, holds the state of the UI and triggers re-renders.

  use GenServer

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Orange.{Rect, CustomComponent, RawText, Renderer, Terminal, Runtime}

  def child_spec([root]) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, root, [name: __MODULE__]]},
      restart: :temporary
    }
  end

  @impl true
  def init(root) do
    Runtime.ComponentRegistry.init()

    terminal_impl().enter_alternate_screen()
    terminal_impl().enable_raw_mode()
    terminal_impl().hide_cursor()

    state = %{
      root: normalize_tree_node(root),
      terminal_size: terminal_impl().terminal_size(),
      previous_tree: nil,
      previous_buffer: nil
    }

    Process.flag(:trap_exit, true)
    {:ok, state, {:continue, :tick}}
  end

  @impl true
  def terminate(_reason, _state) do
    terminal_impl().leave_alternate_screen()
    terminal_impl().disable_raw_mode()
    terminal_impl().show_cursor()

    :ok
  end

  # Walk the tree and normalize tree nodes: 
  # 1. Orange.CustomComponent or {Orange.CustomComponent, attrs} -> %Orange.CustomComponent{}
  defp normalize_tree_node(root) do
    case root do
      module when is_atom(module) ->
        %CustomComponent{module: module}

      {module, attrs} when is_atom(module) ->
        # Expand the children
        attrs =
          Keyword.update(attrs, :children, [], fn children ->
            children |> Enum.reject(&is_nil/1) |> Enum.map(&normalize_tree_node/1)
          end)

        %CustomComponent{module: module, attributes: attrs}

      leaf when is_binary(leaf) ->
        leaf

      {:raw_text, _, _} = node ->
        Orange.RawText.build(node)

      %RawText{} = node ->
        node

      _ ->
        children =
          (root.children || [])
          |> Enum.reject(&is_nil/1)
          |> Enum.map(&normalize_tree_node/1)

        %{root | children: children}
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
    {duration, _} =
      :timer.tc(
        fn -> process_update(ref, callback_or_value) end,
        :millisecond
      )

    Logger.debug("State update took #{duration}ms")
    {:noreply, state}
  end

  # TODO: maybe move process_update out of the runtime loop main process
  defp process_update(ref, callback_or_value) do
    %{state: component_state} = Runtime.ComponentRegistry.get(ref)

    new_component_state =
      if is_function(callback_or_value, 1),
        do: callback_or_value.(component_state),
        else: callback_or_value

    version = Runtime.ComponentRegistry.update_state(ref, new_component_state)

    is_dispatching_event = Process.get({__MODULE__, :dispatching_event})

    # If we are in event dispatching phase, we don't need to manually schedule the render
    # because a render is scheduled at the end of the this phase.
    if !is_dispatching_event do
      # We perform re-render asynchronously. This way we can potentially batch
      # multiple state updates and avoid redundant re-renders.
      # We delay the render at most 20ms
      now = System.monotonic_time(:millisecond)
      send(self(), {:state_updated, version, now})
    end
  end

  defp dispatch_event(event) do
    now = System.monotonic_time(:millisecond)

    Process.put({__MODULE__, :dispatching_event}, true)
    event_manager_impl().dispatch_event(event)
    Process.delete({__MODULE__, :dispatching_event})

    Logger.debug("""
    Dispatch event:
    - event: #{inspect(event, pretty: true)}
    - duration: #{System.monotonic_time(:millisecond) - now}ms
    """)
  end

  @impl true
  def handle_info({:event, event}, state) do
    dispatch_event(event)

    state =
      case event do
        %Terminal.ResizeEvent{width: w, height: h} ->
          %{state | terminal_size: {w, h}}
          |> render_tick(clean_buffer: true)

        %Terminal.KeyEvent{} ->
          if Runtime.ComponentRegistry.has_dirty_components?() do
            render_tick(state)
          else
            state
          end
      end

    {:noreply, state}
  end

  @impl true
  def handle_info({:state_updated, version, time}, state) do
    latest_version = Runtime.ComponentRegistry.get_state_version()
    passed_deadline = System.monotonic_time(:millisecond) - time > 20

    state = if version == latest_version or passed_deadline, do: render_tick(state), else: state

    {:noreply, state}
  end

  @impl true
  # Users code can link the main process to other processes
  # We should expect EXIT messages since we set trap_exit = true
  def handle_info({:EXIT, _pid, _reason}, state) do
    {:noreply, state}
  end

  defp render_tick(state, opts \\ []) do
    dirty_components = Runtime.ComponentRegistry.get_dirty_components()
    Runtime.ComponentRegistry.reset_dirty_components()

    Tracer.with_span "render_tick" do
      {current_tree, mounting_components, unmounting_components} =
        Tracer.with_span "to_component_tree" do
          to_component_tree(state.root, state.previous_tree, dirty_components)
        end

      Process.put({__MODULE__, :component_tree}, current_tree)

      {width, height} = state.terminal_size

      {current_buffer, layout_tree_id_map} =
        Tracer.with_span "render" do
          render_tree = to_render_tree(current_tree)
          Renderer.render(render_tree, %{width: width, height: height})
        end

      Process.put({__MODULE__, :layout_tree_id_map}, layout_tree_id_map)

      Tracer.with_span "draw" do
        if opts[:clean_buffer] do
          terminal_impl().clear()
          terminal_impl().draw(current_buffer, nil)
        else
          terminal_impl().draw(current_buffer, state.previous_buffer)
        end
      end

      after_mount(mounting_components)
      after_unmount(unmounting_components)

      %{state | previous_tree: current_tree, previous_buffer: current_buffer}
    end
  end

  # We need to expand all custom components to their rendered children. Also, we need to
  # persist the state of the custom components between renders.
  # The algorithm is as follows:
  # 1. Walk the current tree and compare with the corresponding node in the previous tree (use expand_with_prev/2). Except for the first render, when the previous tree is not available, use expand_new/1
  # 2. Compare the current node to the previous node:
  #   a. If the nodes are of the same type, diff their children and expand them recursively. If the current
  #    node is a custom component, copy the state from the previous node.
  #   b. If the nodes are of different types, expand the current node as new
  defp to_component_tree(component, previous_tree, dirty_components) do
    Process.put({__MODULE__, :mounting_components}, [])
    Process.put({__MODULE__, :unmounting_components}, [])

    expanded_tree =
      if previous_tree do
        Tracer.set_attribute("type", "expand_with_prev")

        expand_with_prev(component, previous_tree,
          dirty_components: dirty_components,
          subtree_dirty?: false
        )
      else
        Tracer.set_attribute("type", "expand_new")
        expand_new(component)
      end

    mounting_components = Process.get({__MODULE__, :mounting_components})
    unmounting_components = Process.get({__MODULE__, :unmounting_components})

    {expanded_tree, mounting_components, unmounting_components}
  end

  defp expand_new(component) when is_binary(component), do: component

  defp expand_new(%Rect{} = component),
    do: %{component | children: Enum.map(component.children, &expand_new/1)}

  defp expand_new(%RawText{} = node), do: node

  # Custom components
  defp expand_new(%CustomComponent{module: module, attributes: attrs} = component) do
    result = apply(module, :init, [attrs])
    ref = Runtime.ComponentRegistry.register(result.state, attrs, module)

    render_result = apply(module, :render, [result.state, attrs, &update_callback(ref, &1)])

    children =
      if render_result do
        [
          render_result
          |> normalize_tree_node()
          |> expand_new()
        ]
      else
        []
      end

    %{component | children: children, render_result: render_result, ref: ref}
    |> tap(fn component ->
      opts = [events_subscription: Map.get(result, :events_subscription, false)]
      add_to_mounting_list(component, opts)
    end)
  end

  defp add_to_mounting_list(component, opts) do
    to_mount = Process.get({__MODULE__, :mounting_components})
    Process.put({__MODULE__, :mounting_components}, [{component, opts} | to_mount])
  end

  defp add_to_unmounting_list(%CustomComponent{} = component) do
    to_unmount = Process.get({__MODULE__, :unmounting_components})
    Process.put({__MODULE__, :unmounting_components}, [component | to_unmount])
    Enum.each(component.children, &add_to_unmounting_list/1)
  end

  defp add_to_unmounting_list(%Rect{} = component),
    do: Enum.each(component.children, &add_to_unmounting_list/1)

  defp add_to_unmounting_list(_component), do: :noop

  defp expand_with_prev(%Rect{} = component, %Rect{} = previous_tree, opts) do
    diffs = Runtime.ChildrenDiff.run(component.children, previous_tree.children)

    new_children =
      Enum.map(diffs, fn
        {:keep, current, previous} ->
          expand_with_prev(current, previous, opts)

        {:new, current} ->
          expand_new(current)

        {:remove, previous} ->
          add_to_unmounting_list(previous)
          nil
      end)
      |> Enum.reject(&is_nil/1)

    %{component | children: new_children}
  end

  defp expand_with_prev(%Rect{} = component, previous_tree, _) do
    add_to_unmounting_list(previous_tree)
    expand_new(component)
  end

  # Discard the previous tree
  defp expand_with_prev(component, previous_tree, _) when is_binary(component) do
    add_to_unmounting_list(previous_tree)
    component
  end

  # If a component is dirty, all of its descendants is dirty too.
  defp expand_with_prev(
         %CustomComponent{module: module, attributes: attrs},
         %CustomComponent{module: module} = previous_component,
         opts
       ) do
    %{state: state} = Runtime.ComponentRegistry.get(previous_component.ref)

    Runtime.ComponentRegistry.update_attributes(previous_component.ref, attrs)

    state =
      with true <- function_exported?(module, :before_update, 3),
           {:update, new_state} <-
             apply(module, :before_update, [
               state,
               attrs,
               &update_callback(previous_component.ref, &1)
             ]) do
        Runtime.ComponentRegistry.update_state(previous_component.ref, new_state)
        new_state
      else
        _ -> state
      end

    dirty_components = Keyword.get(opts, :dirty_components, [])
    subtree_dirty? = Keyword.get(opts, :subtree_dirty?, false)

    is_dirty = subtree_dirty? or previous_component.ref in dirty_components

    render_result =
      if is_dirty do
        apply(module, :render, [
          state,
          attrs,
          &update_callback(previous_component.ref, &1)
        ])
      else
        # Optimization: if the current component is not dirty, we can reuse the previous component children
        previous_component.render_result
      end

    if render_result do
      current_child = normalize_tree_node(render_result)

      child =
        case previous_component.children do
          [] ->
            expand_new(current_child)

          [prev_child] ->
            # If the current component is dirty, all of its descendants is dirty too.
            expand_with_prev(current_child, prev_child,
              dirty_components: dirty_components,
              subtree_dirty?: is_dirty
            )
        end

      %{previous_component | children: [child], render_result: render_result}
    else
      %{previous_component | children: [], render_result: nil}
    end
  end

  defp expand_with_prev(%CustomComponent{} = component, previous_tree, _) do
    add_to_unmounting_list(previous_tree)
    expand_new(component)
  end

  defp to_render_tree(component) do
    case component do
      text when is_binary(text) ->
        text

      %Rect{} ->
        children = component.children |> Enum.map(&to_render_tree/1) |> Enum.reject(&is_nil/1)
        %{component | children: children}

      %CustomComponent{children: []} ->
        nil

      %CustomComponent{children: [child]} ->
        to_render_tree(child)

      %RawText{} = node ->
        node
    end
  end

  def make_update_callback(component_ref), do: &update_callback(component_ref, &1)

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

  @impl true
  def handle_call({:component_ref_by_id, component_id}, _from, state) do
    {:reply, do_component_ref_by_id(component_id), state}
  end

  @impl true
  def handle_call({:layout_node_by_id, component_id}, _from, state) do
    {:reply, do_layout_node_by_id(component_id), state}
  end

  # Given a component_id, returns the component ref
  def component_ref_by_id(component_id) do
    render_loop_pid = GenServer.whereis(__MODULE__)

    # In case the caller is the render loop, don't GenServer.call cause we will be blocked indefinitely
    if self() == render_loop_pid,
      do: do_component_ref_by_id(component_id),
      else: GenServer.call(__MODULE__, {:component_ref_by_id, component_id})
  end

  defp do_component_ref_by_id(component_id) do
    component =
      Process.get({__MODULE__, :component_tree})
      |> find_by_id(component_id)

    case component do
      %{ref: ref} -> ref
      _ -> nil
    end
  end

  defp find_by_id(%Rect{} = component, component_id),
    do: find_in_children(component.children, component_id)

  defp find_by_id(
         %CustomComponent{children: children, attributes: attributes} = component,
         component_id
       ) do
    if Keyword.has_key?(attributes, :id) && component_id == attributes[:id],
      do: component,
      else: find_in_children(children, component_id)
  end

  defp find_by_id(_, _), do: nil

  defp find_in_children([], _component_id), do: nil

  defp find_in_children([child | remain], component_id) do
    case find_by_id(child, component_id) do
      nil -> find_in_children(remain, component_id)
      component -> component
    end
  end

  # Given a component_id, returns the layout node. The layout node contains the layout information of the element: size,
  # padding, border, margin, etc.
  def layout_node_by_id(component_id) do
    render_loop_pid = GenServer.whereis(__MODULE__)

    # In case the caller is the render loop, don't GenServer.call cause we will be blocked indefinitely
    if self() == render_loop_pid,
      do: do_layout_node_by_id(component_id),
      else: GenServer.call(__MODULE__, {:layout_node_by_id, component_id})
  end

  defp do_layout_node_by_id(component_id) do
    map = Process.get({__MODULE__, :layout_tree_id_map})
    if map, do: Map.get(map, component_id)
  end
end
