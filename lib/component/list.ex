defmodule Orange.Component.List do
  @moduledoc """
  A scrollable list component that supports keyboard navigation.

  ## Attributes

    * `:items` - A list of items. Each item is a map with the following required keys:
      * `:key` - The unique identifier of the item
      * `:item` - The element to render
      * `:height` - The height of the item

      This attribute is required.

    * `:selected_item` - The key of the currently selected item. This attribute is optional.

    * `:on_selected_item_change` - A function that is called when the selected item changes. 
      It receives the key of the newly selected item. This attribute is optional.

    * `:scroll_offset` - The current scroll_y offset. This attribute is optional. Defaults to 0.

    * `:on_scroll_offset_change` - A function that is called when the scroll_y offset changes.
      It receives the new scroll offset. This attribute is optional.

    * `:disabled` - Whether the list is disabled (non-interactive). When disabled, all keyboard events are ignored. This attribute is optional.

    * `:empty_placeholder` - Content to display when the list is empty. This attribute is optional.

    * `:show_scroll_bar` - Whether to show the scroll bar. This is useful if you want to control how the scrollbar is rendered.
      Defaults to `true`. This attribute is optional.

    * `:style` - The list custom style. See `Orange.Macro.rect/2` for supported values. This attribute is optional.

    * `:item_style` - A function that returns the item custom style. It receives is_selected argument, whether the item is selected or not.
      See `Orange.Macro.rect/2` for supported values. This attribute is optional.

  ## Keyboard Navigation

    * `j` - Move to the next item
    * `k` - Move to the previous item

  ## Examples

      defmodule Example do
        @behaviour Orange.Component

        @impl true
        def init(_attrs),
          do: %{state: %{selected_item: :item1, scroll_offset: 0}, events_subscription: true}

        @impl true
        def handle_event(event, _state, _attrs, _update) do
          case event do
            %Orange.Terminal.KeyEvent{code: {:char, "q"}} ->
              Orange.stop()
              :noop

            _ ->
              :noop
          end
        end

        @impl true
        def render(state, _attrs, update) do
          items =
            for i <- 1..10 do
              %{key: :\"item\#{i}\", item: \"Item \#{i}\", height: 1}
            end

          {
            Orange.Component.List,
            items: items,
            selected_item: state.selected_item,
            on_selected_item_change: fn key ->
              update.(fn state -> %{state | selected_item: key} end)
            end,
            scroll_offset: state.scroll_offset,
            on_scroll_offset_change: fn offset ->
              update.(fn state -> %{state | scroll_offset: offset} end)
            end,
            empty_placeholder: "No items",
            style: [border: true, height: 7],
            item_style: fn is_selected ->
              if is_selected, do: [background_color: :blue, color: :black], else: []
            end
          }
        end
      end

    ![rendered result](assets/list-example.gif)
  """

  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_),
    do: %{
      state: %{id: make_ref(), mounted: false},
      events_subscription: true
    }

  @impl true
  def handle_event(event, state, attrs, _update) do
    if !attrs[:disabled] do
      case event do
        %Orange.Terminal.KeyEvent{code: {:char, "j"}} ->
          move_to_next_item(state, attrs)

        %Orange.Terminal.KeyEvent{code: {:char, "k"}} ->
          move_to_prev_item(attrs)

        _ ->
          nil
      end
    end

    :noop
  end

  @impl true
  def after_mount(_state, _attrs, update) do
    # Force re-render because we now have layout measurements after the first render
    update.(fn state -> %{state | mounted: true} end)
  end

  defp move_to_next_item(state, attrs) do
    selected_item_index =
      Enum.find_index(attrs[:items], &(&1.key == attrs[:selected_item]))

    layout_size = Orange.get_layout_size(state.id)

    with %{height: available_height} <- layout_size do
      cond do
        selected_item_index == nil ->
          :noop

        selected_item_index == length(attrs[:items]) - 1 ->
          :noop

        true ->
          next_item = selected_item_index + 1

          target_scroll_offset =
            item_start_offset(attrs[:items], next_item) + Enum.at(attrs[:items], next_item).height

          trigger_on_selected_item_change(attrs, next_item)

          if target_scroll_offset > attrs[:scroll_offset] + available_height do
            # The next item is not fully visible, scroll down
            attrs[:on_scroll_offset_change].(target_scroll_offset - available_height)
          end
      end
    end
  end

  defp move_to_prev_item(attrs) do
    selected_item_index =
      Enum.find_index(attrs[:items], &(&1.key == attrs[:selected_item]))

    cond do
      selected_item_index == nil ->
        :noop

      selected_item_index == 0 ->
        :noop

      true ->
        previous_item = selected_item_index - 1
        target_scroll_offset = item_start_offset(attrs[:items], previous_item)

        trigger_on_selected_item_change(attrs, previous_item)

        if target_scroll_offset < attrs[:scroll_offset] do
          # The prev item is not fully visible, scroll up
          attrs[:on_scroll_offset_change].(target_scroll_offset)
        end
    end
  end

  # Get the scroll offset of the start of the item
  defp item_start_offset(_items, 0), do: 0

  defp item_start_offset(items, index) do
    for i <- 0..(index - 1) do
      item = Enum.at(items, i)
      Map.get(item, :height, 1)
    end
    |> Enum.sum()
  end

  defp trigger_on_selected_item_change(attrs, new_index) do
    %{key: item_key} = Enum.at(attrs[:items], new_index)
    if attrs[:on_selected_item_change], do: attrs[:on_selected_item_change].(item_key)
  end

  defp overflow?(state, attrs) do
    layout_size = Orange.get_layout_size(state.id)

    case layout_size do
      %{height: available_height} ->
        total_height = Enum.map(attrs[:items], & &1.height) |> Enum.sum()
        total_height > available_height

      _ ->
        false
    end
  end

  defp item_style(attrs, item_key) do
    is_selected = attrs[:selected_item] == item_key

    base_style =
      if is_selected, do: [background_color: :dark_grey, padding: {0, 1}], else: [padding: {0, 1}]

    custom_style = if attrs[:item_style], do: attrs[:item_style].(is_selected), else: []
    Keyword.merge(base_style, custom_style)
  end

  @impl true
  def render(state, attrs, _update) do
    scroll_offset = if overflow?(state, attrs), do: attrs[:scroll_offset]
    scroll_y = if Keyword.get(attrs, :show_scroll_bar, true), do: scroll_offset

    if attrs[:items] != [] do
      style = Keyword.merge([min_height: 0], attrs[:style] || [])

      rect style: style, scroll_y: scroll_y do
        rect id: state.id, style: [flex_direction: :column, min_height: 0] do
          for %{key: item_key, item: item} <- attrs[:items] do
            rect style: item_style(attrs, item_key) do
              item
            end
          end
        end
      end
    else
      style = Keyword.merge([padding: {0, 1}], attrs[:style] || [])

      rect style: style do
        attrs[:empty_placeholder]
      end
    end
  end
end
