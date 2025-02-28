defmodule Orange.Layout.InputTreeNode do
  @moduledoc false

  # The layout tree uses as the input of the layout API.

  @type child :: {:text, binary()} | {:node, __MODULE__.t()}

  @type t :: %__MODULE__{
          id: integer(),
          children: list(child()),
          style: __MODULE__.Style.t()
        }

  defstruct [:id, :children, :style]

  defmodule Style do
    @moduledoc false

    # The style of layout tree node
    # Supports only a subset of styling properties that affect the layout.

    @type length_or_percent :: {:fixed | integer()} | {:percentage, float()}

    @type t :: %__MODULE__{
            # Can be a percentage or a fixed value
            width: length_or_percent() | nil,
            min_width: length_or_percent() | nil,
            max_width: length_or_percent() | nil,
            height: {:fixed | integer()} | {:percentage, float()} | nil,
            min_height: length_or_percent() | nil,
            max_height: length_or_percent() | nil,
            padding: {integer(), integer(), integer(), integer()},
            margin: {integer(), integer(), integer(), integer()},
            border: {integer(), integer(), integer(), integer()},
            display: :flex | :grid,
            flex_direction: :row | :column,
            flex_grow: integer(),
            flex_shrink: integer(),
            justify_content:
              :start | :end | :center | :space_between | :space_around | :space_evenly | :stretch,
            align_items:
              :start | :end | :center | :space_between | :space_around | :space_evenly | :stretch,
            line_wrap: boolean(),
            row_gap: integer() | nil,
            column_gap: integer() | nil,
            grid_template_rows: list(grid_track()) | nil,
            grid_template_columns: list(grid_track()) | nil,
            grid_row: grid_lines(),
            grid_column: grid_lines()
          }

    @type grid_track ::
            integer()
            | binary()
            | {:fr, integer()}
            | :auto
            | {:repeat, integer(), length_or_percent() | {:fr, integer()}}

    @type grid_line :: {:fixed, integer()} | {:span, integer()} | :auto
    @type grid_lines :: {:single, grid_line()} | {:double, grid_line(), grid_line()}

    defstruct [
      :width,
      :min_width,
      :max_width,
      :height,
      :min_height,
      :max_height,
      :padding,
      :margin,
      :border,
      :display,
      :flex_direction,
      :flex_grow,
      :flex_shrink,
      :justify_content,
      :align_items,
      :line_wrap,
      :grid_template_rows,
      :grid_template_columns,
      :grid_row,
      :grid_column,
      :row_gap,
      :column_gap
    ]
  end
end

defmodule Orange.Layout.OutputTreeNode do
  @moduledoc false

  # The layout tree uses as the output of the layout API.
  # This tree includes the layout information (position, sizes, ...) of the tree.

  @type children :: {:text, binary()} | {:nodes, list(__MODULE__.t())} | nil

  @type t :: %__MODULE__{
          id: integer(),
          width: integer(),
          height: integer(),
          x: integer(),
          y: integer(),
          abs_x: integer(),
          abs_y: integer(),
          content_text_lines: list(binary()) | nil,
          content_size: {integer(), integer()},
          scrollbar_size: {integer(), integer()},
          border: __MODULE__.FourValues.t(),
          padding: __MODULE__.FourValues.t(),
          margin: __MODULE__.FourValues.t(),
          children: children()
        }

  defstruct [
    :id,
    :width,
    :height,
    :x,
    :y,
    :abs_x,
    :abs_y,
    :content_text_lines,
    :content_size,
    :scrollbar_size,
    :border,
    :padding,
    :margin,
    :children
  ]

  defmodule FourValues do
    @moduledoc false

    @type t :: %__MODULE__{
            left: integer(),
            right: integer(),
            top: integer(),
            bottom: integer()
          }

    defstruct [:left, :right, :top, :bottom]
  end
end
