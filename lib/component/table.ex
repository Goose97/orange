defmodule Orange.Component.Table do
  @moduledoc """
  A scrollable table component with sortable columns and keyboard navigation.

  ## Attributes

    * `:columns` - A list of column definitions. Each column is a map with the following keys:
      * `:id` - The unique identifier of the column
      * `:name` - The display name of the column
      * `:sort_key` - (Optional) A character key that can be pressed to sort by this column
      * `:render` - (Optional) A function that renders a cell value. Defaults to `to_string/1`

      This attribute is required.

    * `:rows` - A list of rows. Each row is a tuple of `{row_key, row_values}`, where:
      * `row_key` - A unique identifier for the row
      * `row_values` - A list of values, one for each column

      This attribute is required.

    * `:selected_row_index` - The index of the currently selected row. This attribute is optional.

    * `:on_selected_row_change` - A function that is called when moving to a different row.
      It receives the new row index. This attribute is optional.

    * `:on_row_select` - A function that is called when a row is selected (Enter key).
      It receives the row_key of the selected row. This attribute is optional.

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

    * `:border_color` - The color of the table borders. This attribute is optional.

    * `:disabled` - Whether the table is disabled (non-interactive). When disabled, all keyboard events are ignored. This attribute is optional.

    * `:style` - The table custom style. See `Orange.Macro.rect/2` for supported values. This attribute is optional.

  ## Keyboard Navigation

    * `j` - Move to the next row
    * `k` - Move to the previous row
    * `>` - Go to the next page
    * `<` - Go to the previous page
    * `Enter` - Select the current row
    * `L` - Scroll right (when table is wider than the viewport)
    * `H` - Scroll left (when table is wider than the viewport)
    * `[sort_key]` - Sort by the column with the matching sort_key

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
            on_row_select: fn row_key -> IO.puts(\"Selected row: \#{row_key}\") end,
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
            border_color: :blue,
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
          if attrs[:on_selected_row_change] && state.page_size &&
               attrs[:selected_row_index] < state.page_size - 1,
             do: attrs[:on_selected_row_change].(attrs[:selected_row_index] + 1)

          :noop

        %Orange.Terminal.KeyEvent{code: {:char, "k"}} ->
          if attrs[:on_selected_row_change] && attrs[:selected_row_index] > 0,
            do: attrs[:on_selected_row_change].(attrs[:selected_row_index] - 1)

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

        %Orange.Terminal.KeyEvent{code: :enter} ->
          selected_row_index = attrs[:selected_row_index]
          rows = Process.get({__MODULE__, state.id, :rows})

          if selected_row_index != nil and selected_row_index < length(rows) do
            {row_key, _} = Enum.at(rows, selected_row_index)
            if on_row_select = attrs[:on_row_select], do: on_row_select.(row_key)
          end

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

        %Orange.Terminal.KeyEvent{code: {:char, char}} ->
          column = Enum.find(attrs[:columns], fn column -> Map.get(column, :sort_key) == char end)

          if column do
            sort_column = update_sort_column(attrs[:sort_column], column.id)
            if attrs[:on_sort_change], do: attrs[:on_sort_change].(sort_column)
          end

          :noop

        _ ->
          :noop
      end
    else
      :noop
    end
  end

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

  defp column_name(%{id: sort_column_id} = column, {sort_column_id, direction}) do
    direction_text =
      case direction do
        :desc -> "▼"
        :asc -> "▲"
      end

    rect do
      column_with_sort_key(column)
      " #{direction_text}"
    end
  end

  defp column_name(column, _), do: column_with_sort_key(column)

  defp column_with_sort_key(column) do
    if sort_key = Map.get(column, :sort_key) do
      rect do
        column.name

        rect style: [margin: {0, 0, 0, 1}, color: :blue] do
          "(#{sort_key})"
        end
      end
    else
      column.name
    end
  end

  defp sort_rows(rows, nil, _), do: rows

  defp sort_rows(rows, {sort_column, direction}, columns) do
    index = Enum.find_index(columns, &(&1.id == sort_column))
    Enum.sort_by(rows, fn {_, row} -> Enum.at(row, index) end, direction)
  end

  defp header_separator(attrs) do
    [
      rect position: {:absolute, 2, 0, nil, nil}, style: [color: attrs[:border_color]] do
        "┤"
      end,
      rect position: {:absolute, 2, nil, nil, 0}, style: [color: attrs[:border_color]] do
        "├"
      end
    ]
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

    row_width =
      Enum.intersperse(column_widths, cell_gap)
      |> Enum.sum()
      |> Kernel.+(padding_x * 2)

    {children, footer} =
      if state.page_size do
        current_row =
          current_page  * state.page_size + attrs[:selected_row_index] + 1

        footer =
          if attrs[:footer],
            do: attrs[:footer].(%{current_row: current_row, total_rows: length(all_rows)}),
            else: "< #{current_row} of #{length(all_rows)} >"

        start_index = current_page * state.page_size
        rows_in_page = Enum.slice(all_rows, start_index, state.page_size)

        rows_to_render =
          rows_in_page
          |> Enum.with_index()
          |> Enum.map(fn {{row_key, row}, index} ->
            row_background_color = if attrs[:selected_row_index] == index, do: :dark_grey

            custom_row_style =
              if row_style_fn = attrs[:row_style], do: row_style_fn.(row_key), else: []

            row_style =
              Keyword.merge(
                [
                  background_color: row_background_color,
                  padding: {0, padding_x},
                  gap: cell_gap,
                  flex_shrink: 0,
                  width: row_width
                ],
                custom_row_style
              )

            rect style: row_style do
              row
              |> Enum.with_index()
              |> Enum.map(fn {content, index} ->
                width = Enum.at(column_widths, index)

                rect style: [width: width, flex_direction: :column, flex_shrink: 0] do
                  content
                end
              end)
            end
          end)

        {rows_to_render, %{text: footer, offset: 1}}
      else
        {[], nil}
      end

    rect id: state.id,
         style: [
           flex_direction: :column,
           min_height: 0,
           flex_grow: 1,
           border_left: true,
           border_right: true,
           border_bottom: true,
           border_style: :round_corners,
           border_color: attrs[:border_color]
         ],
         footer: footer,
         scroll_x: state.scroll_offset_x do
      children
    end
  end

  # Calculate the width for each column
  defp prepare_render(columns, rows) do
    rows =
      Enum.map(rows, fn {row_key, row} ->
        contents =
          row
          |> Enum.with_index()
          |> Enum.map(fn {value, index} ->
            column = Enum.at(columns, index)
            render_fn = Map.get(column, :render, &to_string/1)
            render_fn.(value)
          end)

        {row_key, contents}
      end)

    row_heights =
      for {_, contents} <- rows do
        Enum.map(contents, &(String.split(&1, "\n") |> length()))
        |> Enum.max()
      end

    column_widths =
      Enum.map(0..(length(columns) - 1), fn index ->
        column = Enum.at(columns, index)
        header_width = String.length(column.name)
        # Plus 2 for the possible sort indicator and sort key length
        header_width =
          if sort_key = Map.get(column, :sort_key),
            do: header_width + 2 + String.length(sort_key) + 3,
            else: header_width

        row_widths =
          Enum.map(rows, fn {_, contents} ->
            Enum.at(contents, index)
            |> String.split("\n")
            |> Enum.map(&String.length/1)
            |> Enum.max()
          end)

        Enum.max([header_width | row_widths])
      end)

    {rows, column_widths, row_heights}
  end

  defp headers(columns, column_widths, state, attrs) do
    rect style: [
           gap: 2,
           width: "100%",
           padding: {0, 1},
           border: true,
           text_modifiers: [:bold],
           scroll_bar: :hidden,
           border_style: :round_corners,
           border_color: attrs[:border_color]
         ],
         scroll_x: state.scroll_offset_x do
      Enum.zip(columns, column_widths)
      |> Enum.map(fn {column, width} ->
        # Plus 2 for the padding
        rect style: [width: width, flex_shrink: 0] do
          column_name(column, attrs[:sort_column])
        end
      end)
    end
  end

  @impl true
  def render(state, attrs, _update) do
    columns = attrs[:columns]

    rows = sort_rows(attrs[:rows], attrs[:sort_column], columns)
    {rows, column_widths, row_heights} = prepare_render(columns, rows)
    Process.put({__MODULE__, state.id, :rows}, rows)

    custom_style = Keyword.get(attrs, :style, [])

    container_style =
      Keyword.merge(
        [flex_direction: :column, width: "100%", height: "100%", min_height: 0],
        custom_style
      )

    Process.put({__MODULE__, state.id, :row_heights}, row_heights)

    rect style: container_style do
      headers(columns, column_widths, state, attrs)
      header_separator(attrs)
      rows(rows, column_widths, state, attrs)
    end
  end
end
