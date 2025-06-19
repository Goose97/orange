defmodule Orange.Component.Table do
  @moduledoc """
  A scrollable table component with sortable columns and keyboard navigation.

  ## Attributes

    * `:columns` - A list of column definitions. Each column is a map with the following keys:
      * `:id` - The unique identifier of the column
      * `:name` - A string used as column header
      * `:sort_key` - (Optional) A character key that can be pressed to sort by this column
      * `:render` - (Optional) A function that renders a cell value, returns a string. Defaults to `to_string/1`

      This attribute is required.

    * `:rows` - A list of rows. Each row is a tuple of `{row_key, row_values}`, where:
      * `row_key` - A unique identifier for the row
      * `row_values` - A list of values, one for each column

      This attribute is required.

    * `:selected_row_index` - The index of the currently selected row. This attribute is optional.

    * `:on_selected_row_change` - A function that is called when moving to a different row.
      It receives the new row index. This attribute is optional.

    * `:actions` - A list of key-action pairs for custom keyboard actions on rows.
      Each pair is a tuple of `{key_code, callback}`, where:
      * `key_code` - A [key code](`Orange.Terminal.KeyEvent#key_code`)
      * `callback` - A function that receives the row_key of the selected row
      
      This attribute is optional.

    * `:current_page` - The current page number (0-based). This attribute is optional. Defaults to 0.

    * `:on_page_change` - A function that is called when changing pages.
      It receives the new page number. This attribute is optional.

    * `:sort_column` - The current sort configuration as a tuple of `{column_id, direction}`, where:
      * `column_id` - The ID of the column to sort by
      * `direction` - Either `:asc` or `:desc`

      This attribute is optional.

    * `:on_sort_change` - A function that is called when the sort configuration changes.
      It receives the new sort configuration. This attribute is optional.

    * `:footer` - A function that renders the footer. It receives a map with:
      * `:current_row` - The index of the current row (across all pages)
      * `:total_rows` - The total number of rows

      This attribute is optional. Defaults to "< [current_row] of [total_rows] >".

    * `:row_style` - A function that returns custom styles for a row. It receives the row_key.
      See `Orange.Macro.rect/2` for supported values. This attribute is optional.

    * `:colors` - A map with color customization options:
      * `:border` - The color of the table borders
      * `:sort_key` - The color of the sort key indicators. Defaults to `:blue`
      * `:selected_row_bg` - The background color of the selected row. Defaults to `:dark_grey`
      * `:selected_row_fg` - The foreground color of the selected row
      
      This attribute is optional.

    * `:disabled` - Whether the table is disabled (non-interactive). When disabled, all keyboard events are ignored. This attribute is optional.

    * `:style` - The table custom style. See `Orange.Macro.rect/2` for supported values. This attribute is optional.

  ## Keyboard Navigation

    * `j` - Move to the next row
    * `k` - Move to the previous row
    * `>` - Go to the next page
    * `<` - Go to the previous page
    * `L` - Scroll right (when table is wider than the viewport)
    * `H` - Scroll left (when table is wider than the viewport)
    * `[sort_key]` - Sort by the column with the matching sort_key
    * Custom keys defined in `:actions` - Perform the associated action on the selected row

  ## Examples

      defmodule Example do
        @behaviour Orange.Component

        @impl true
        def init(_attrs),
          do: %{
            state: %{
              selected_row_index: 0,
              current_page: 0,
              sort_column: {:name, :desc}
            },
            events_subscription: true
          }

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
          columns = [
            %{id: :name, name: "Name", sort_key: "n"},
            %{id: :age, name: "Age", sort_key: "a"},
            %{id: :email, name: "Email", sort_key: "e"}
          ]

          rows = [
            {:user1, ["Alice", 28, "alice@example.com"]},
            {:user2, ["Bob", 34, "bob@example.com"]},
            {:user3, ["Charlie", 22, "charlie@example.com"]},
            {:user4, ["Diana", 31, "diana@example.com"]}
          ]

          {
            Orange.Component.Table,
            columns: columns,
            rows: rows,
            selected_row_index: state.selected_row_index,
            on_selected_row_change: fn index ->
              update.(fn state -> %{state | selected_row_index: index} end)
            end,
            actions: [
              {{:char, "e"}, fn row_key -> IO.puts(\"Editing row: \#{row_key}\") end},
              {{:char, "d"}, fn row_key -> IO.puts(\"Deleting row: \#{row_key}\") end}
            ],
            current_page: state.current_page,
            on_page_change: fn page ->
              update.(fn state -> 
                %{state | current_page: page, selected_row_index: 0} 
              end)
            end,
            sort_column: state.sort_column,
            on_sort_change: fn sort_column ->
              update.(fn state -> %{state | sort_column: sort_column} end)
            end,
            colors: %{border: :blue, selected_row_bg: :dark_grey},
            style: [height: 10]
          }
        end
      end

    ![rendered result](assets/table-example.gif)
  """

  @behaviour Orange.Component

  import Orange.Macro

  @initial_sort_direction :desc

  @impl true
  def init(_),
    do: %{
      state: %{
        id: make_ref(),
        page_size: nil,
        layout_size: nil,
        scroll_offset_x: 0
      },
      events_subscription: true
    }

  @impl true
  def after_mount(state, _attrs, update) do
    layout_size = Orange.get_layout_size(state.id)
    # Minus the bottom border
    update.(fn state -> %{state | page_size: layout_size.height - 1, layout_size: layout_size} end)
  end

  @impl true
  def handle_event(event, state, attrs, _update) do
    if !attrs[:disabled] do
      case event do
        %Orange.Terminal.KeyEvent{code: {:char, "j"}} ->
          total_pages = ceil(length(attrs[:rows]) / state.page_size)

          last_row_index =
            if attrs[:current_page] < total_pages - 1,
              do: state.page_size - 1,
              else: rem(length(attrs[:rows]), state.page_size) - 1

          if attrs[:on_selected_row_change] &&
               state.page_size &&
               attrs[:selected_row_index] &&
               attrs[:selected_row_index] < last_row_index do
            attrs[:on_selected_row_change].(attrs[:selected_row_index] + 1)
          end

          :noop

        %Orange.Terminal.KeyEvent{code: {:char, "k"}} ->
          if attrs[:on_selected_row_change] &&
               attrs[:selected_row_index] &&
               attrs[:selected_row_index] > 0 do
            attrs[:on_selected_row_change].(attrs[:selected_row_index] - 1)
          end

          :noop

        # Next page
        %Orange.Terminal.KeyEvent{code: {:char, ">"}} ->
          with(
            true <- state.page_size != nil,
            total_pages = ceil(length(attrs[:rows]) / state.page_size),
            current_page = Keyword.get(attrs, :current_page, 0),
            true <- current_page < total_pages - 1
          ) do
            if attrs[:on_page_change], do: attrs[:on_page_change].(current_page + 1)
          end

          :noop

        # Previous page
        %Orange.Terminal.KeyEvent{code: {:char, "<"}} ->
          current_page = Keyword.get(attrs, :current_page, 0)

          if attrs[:on_page_change] && current_page > 0,
            do: attrs[:on_page_change].(current_page - 1)

          :noop

        # Scroll right a quarter of the screen
        %Orange.Terminal.KeyEvent{code: {:char, "L"}} ->
          if state.layout_size do
            step = div(state.layout_size.width, 4)
            {:update, %{state | scroll_offset_x: state.scroll_offset_x + step}}
          else
            :noop
          end

        # Scroll left a quarter of the screen
        %Orange.Terminal.KeyEvent{code: {:char, "H"}} ->
          if state.layout_size do
            step = div(state.layout_size.width, 4)
            {:update, %{state | scroll_offset_x: max(0, state.scroll_offset_x - step)}}
          else
            :noop
          end

        %Orange.Terminal.KeyEvent{code: code} ->
          cond do
            triggered_sort_column = match_sort_key(code, attrs[:columns]) ->
              sort_column = update_sort_column(attrs[:sort_column], triggered_sort_column.id)
              if attrs[:on_sort_change], do: attrs[:on_sort_change].(sort_column)

            (action_callback = match_action(code, attrs[:actions])) && attrs[:selected_row_index] ->
              row_key = get_selected_row_key(state, attrs)
              if row_key, do: action_callback.(row_key)

            :else ->
              nil
          end

          :noop

        _ ->
          :noop
      end
    else
      :noop
    end
  end

  defp match_sort_key({:char, char}, columns),
    do: Enum.find(columns, fn column -> Map.get(column, :sort_key) == char end)

  defp match_sort_key(_, _), do: nil

  # If sort the same column, toggle direction
  defp update_sort_column({sort_column, direction}, sort_column) do
    new_direction =
      case direction do
        :asc -> :desc
        :desc -> :asc
      end

    {sort_column, new_direction}
  end

  # If sort a different column, reset sort column and set the new column direction
  defp update_sort_column(_, new_sort_column), do: {new_sort_column, @initial_sort_direction}

  defp match_action(_, nil), do: nil

  defp match_action(code, actions) do
    Enum.find_value(actions, fn
      {^code, callback} -> callback
      _ -> nil
    end)
  end

  defp get_selected_row_key(state, attrs) do
    # We pay the price to re-sort the rows before triggering the action.
    # However, we expect the price is small due to the small size of the table.
    # If performance becomes an issue, we can optimize this by caching the sorted rows.
    current_page = Keyword.get(attrs, :current_page, 0)
    rows = sort_rows(attrs[:rows], attrs[:sort_column], attrs[:columns])
    start_index = current_page * state.page_size
    rows_in_page = Enum.slice(rows, start_index, state.page_size)

    if attrs[:selected_row_index] && attrs[:selected_row_index] < length(rows_in_page) do
      {row_key, _} = Enum.at(rows_in_page, attrs[:selected_row_index])
      row_key
    end
  end

  defp column_name(%{id: sort_column_id} = column, sort, attrs) do
    content = [%{text: column.name}]

    content =
      if sort_key = Map.get(column, :sort_key) do
        sort_key_color = get_in(attrs, [:colors, :sort_key]) || :blue
        content ++ [%{text: " (#{sort_key})", color: sort_key_color}]
      else
        content
      end

    case sort do
      # The column is the currently sorted column
      {^sort_column_id, direction} ->
        direction_text =
          case direction do
            :desc -> "▼"
            :asc -> "▲"
          end

        content ++ [%{text: " #{direction_text}"}]

      _ ->
        content
    end
  end

  defp sort_rows(rows, nil, _), do: rows

  defp sort_rows(rows, {sort_column, direction}, columns) do
    index = Enum.find_index(columns, &(&1.id == sort_column))
    Enum.sort_by(rows, fn {_, row} -> Enum.at(row, index) end, direction)
  end

  defp header_separator(attrs) do
    border_color = get_in(attrs, [:colors, :border])

    rect style: [width: "100%", height: 1, color: border_color] do
      "├" 

      rect style: [flex_grow: 1], background_text: %{text: "─", color: border_color} do
      end

      "┤"
    end
  end

  defp rows(all_rows, column_widths, state, attrs) do
    current_page = Keyword.get(attrs, :current_page, 0)

    # HACK: by default, the row width is constrained by the width of the parent table.
    # But we want the row to be as big as the content, so that the background color works
    # even when we scroll.
    # We handle this by manually calculating the width of the row, accounting for the
    # flex gap and the padding.
    cell_gap = 2
    padding_x = 1

    row_width = Enum.sum(column_widths) + padding_x * 2 + cell_gap * (length(column_widths) - 1)

    {children, footer} =
      if state.page_size do
        current_row =
          cond do
            attrs[:selected_row_index] == nil ->
              nil

            length(all_rows) > 0 ->
              current_page * state.page_size + attrs[:selected_row_index] + 1

            :else ->
              0
          end

        footer =
          if attrs[:footer],
            do: attrs[:footer].(%{current_row: current_row, total_rows: length(all_rows)}),
            else: "< #{current_row || 0} of #{length(all_rows)} >"

        start_index = current_page * state.page_size
        rows_in_page = Enum.slice(all_rows, start_index, state.page_size)

        rows_to_render =
          rows_in_page
          |> Enum.with_index()
          |> Enum.map(fn {{row_key, row}, index} ->
            {row_background_color, row_foreground_color} =
              if attrs[:selected_row_index] == index do
                bg = get_in(attrs, [:colors, :selected_row_bg]) || :dark_grey
                fg = get_in(attrs, [:colors, :selected_row_fg])

                {bg, fg}
              else
                {nil, nil}
              end

            custom_row_style =
              if row_style_fn = attrs[:row_style], do: row_style_fn.(row_key), else: []

            row_style =
              Keyword.merge(
                [
                  background_color: row_background_color,
                  color: row_foreground_color,
                  flex_shrink: 0,
                  width: row_width,
                  height: 1,
                  gap: cell_gap,
                  padding: {0, padding_x}
                ],
                custom_row_style
              )

            raw_text =
              row
              |> Enum.with_index()
              |> Enum.map(fn {content, index} ->
                width = Enum.at(column_widths, index)

                rect style: [width: width, height: 1] do
                  {:raw_text, :row, %{text: content, color: row_style[:color]}}
                end
              end)

            rect style: row_style do
              raw_text
            end
          end)

        {rows_to_render, %{text: footer, offset: 1}}
      else
        {[], nil}
      end

    border_color = get_in(attrs, [:colors, :border])

    rect id: state.id,
         style: [
           flex_direction: :column,
           min_height: 0,
           flex_grow: 1,
           border_left: true,
           border_right: true,
           border_bottom: true,
           border_style: :round_corners,
           border_color: border_color
         ],
         footer: footer,
         scroll_x: state.scroll_offset_x do
      children
    end
  end

  # Calculate the width for each column
  defp prepare_render(columns, rows) do
    columns = List.to_tuple(columns)

    rows =
      Enum.map(rows, fn {row_key, row} ->
        contents =
          row
          |> Enum.with_index()
          |> Enum.map(fn {value, index} ->
            column = elem(columns, index)
            render_fn = Map.get(column, :render, &to_string/1)
            render_fn.(value)
          end)

        {row_key, contents}
      end)

    column_widths =
      Enum.map(0..(tuple_size(columns) - 1), fn index ->
        column = elem(columns, index)
        header_width = String.length(column.name)
        # Plus 2 for the possible sort indicator and sort key length
        header_width =
          if sort_key = Map.get(column, :sort_key),
            do: header_width + 2 + String.length(sort_key) + 3,
            else: header_width

        row_widths =
          Enum.map(rows, fn {_, contents} -> Enum.at(contents, index) |> String.length() end)

        Enum.max([header_width | row_widths])
      end)

    {rows, column_widths}
  end

  defp headers(columns, column_widths, state, attrs) do
    border_color = get_in(attrs, [:colors, :border])

    rect style: [
           gap: 2,
           width: "100%",
           padding: {0, 1},
           border: true,
           border_bottom: false,
           text_modifiers: [:bold],
           scroll_bar: :hidden,
           border_style: :round_corners,
           border_color: border_color
         ],
         scroll_x: state.scroll_offset_x do
      Enum.zip(columns, column_widths)
      |> Enum.map(fn {column, width} ->
        # Plus 2 for the padding
        rect style: [width: width, height: 1, flex_shrink: 0] do
          {:raw_text, :row, column_name(column, attrs[:sort_column], attrs)}
        end
      end)
    end
  end

  @impl true
  def render(state, attrs, _update) do
    columns = attrs[:columns]
    rows = sort_rows(attrs[:rows], attrs[:sort_column], columns)
    {rows, column_widths} = prepare_render(columns, rows)

    container_style =
      Keyword.merge(
        [flex_direction: :column, width: "100%", height: "100%", min_height: 0],
        Keyword.get(attrs, :style, [])
      )

    rect style: container_style do
      headers(columns, column_widths, state, attrs)
      header_separator(attrs)
      rows(rows, column_widths, state, attrs)
    end
  end
end
