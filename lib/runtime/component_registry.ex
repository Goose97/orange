defmodule Orange.Runtime.ComponentRegistry do
  @moduledoc false

  def init() do
    Process.put({:component, :state_version_counter}, :atomics.new(1, []))
  end

  def register(state, attrs, module) do
    component_ref = make_ref()
    Process.put(id(component_ref), {{nil, state}, {nil, attrs}, module})
    component_ref
  end

  def get(component_ref) when is_reference(component_ref) do
    case Process.get(id(component_ref)) do
      {{_prev_state, current_state}, {_prev_attrs, current_attrs}, module} ->
        %{state: current_state, attributes: current_attrs, module: module}

      nil ->
        raise("""
        #{__MODULE__}.get: component not found
        - ref: #{inspect(component_ref)}
        """)
    end
  end

  def update_state(component_ref, new_state) when is_reference(component_ref) do
    case Process.get(id(component_ref)) do
      {{_prev_state, current_state}, attrs, module} ->
        updated_record = {{current_state, new_state}, attrs, module}
        Process.put({:component, component_ref}, updated_record)
        mark_dirty_component(component_ref)

        counter = Process.get({:component, :state_version_counter})
        :atomics.add_get(counter, 1, 1)

      _ ->
        raise("""
        #{__MODULE__}.update_state: component not found
        - ref: #{inspect(component_ref)}
        """)
    end
  end

  defp mark_dirty_component(component_ref) do
    set =
      Process.get(:dirty_components, MapSet.new())
      |> MapSet.put(component_ref)

    Process.put(:dirty_components, set)
  end

  def get_dirty_components(), do: Process.get(:dirty_components, MapSet.new())
  def reset_dirty_components(), do: Process.put(:dirty_components, MapSet.new())

  def has_dirty_components?() do
    size = get_dirty_components() |> MapSet.size()
    size > 0
  end

  def get_state_version() do
    counter = Process.get({:component, :state_version_counter})
    :atomics.get(counter, 1)
  end

  def update_attributes(component_ref, new_attrs) when is_reference(component_ref) do
    case Process.get(id(component_ref)) do
      {state, {_prev_attrs, current_attrs}, module} ->
        updated_record = {state, {current_attrs, new_attrs}, module}
        Process.put({:component, component_ref}, updated_record)

        counter = Process.get({:component, :state_version_counter})
        :atomics.add_get(counter, 1, 1)

      _ ->
        raise("""
        #{__MODULE__}.update_attributes: component not found
        - ref: #{inspect(component_ref)}
        """)
    end
  end

  @compile {:inline, id: 1}
  defp id(component_ref), do: {:component, component_ref}
end
