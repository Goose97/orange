defmodule Orange.Layout.InputTreeNode do
  # The layout tree uses as the input of the layout API.

  @type child :: {:text, binary()} | {:node, __MODULE__.t()}

  @type t :: %__MODULE__{
          id: integer(),
          children: list(child()),
          style: __MODULE__.Style.t()
        }

  defstruct [:id, :children, :style]

  defmodule Style do
    # The style of layout tree node
    # Supports only a subset of styling properties that affect the layout.

    @type t :: %__MODULE__{
            # Can be a percentage or a fixed value
            width: {:fixed | integer()} | {:percentage, float()} | nil,
            height: {:fixed | integer()} | {:percentage, float()} | nil,
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
            line_wrap: boolean()
          }

    defstruct [
      :width,
      :height,
      :padding,
      :margin,
      :border,
      :display,
      :flex_direction,
      :flex_grow,
      :flex_shrink,
      :justify_content,
      :align_items,
      :line_wrap
    ]
  end
end

defmodule Orange.Layout.OutputTreeNode do
  # The layout tree uses as the output of the layout API.
  # This tree includes the layout information (position, sizes, ...) of the tree.

  @type child :: {:text, binary()} | {:node, __MODULE__.t()}

  @type t :: %__MODULE__{
          id: integer(),
          width: integer(),
          height: integer(),
          x: integer(),
          y: integer(),
          content_size: {integer(), integer()},
          border: __MODULE__.FourValues.t(),
          padding: __MODULE__.FourValues.t(),
          margin: __MODULE__.FourValues.t(),
          children: list(child())
        }

  defstruct [:id, :width, :height, :x, :y, :content_size, :border, :padding, :margin, :children]

  defmodule FourValues do
    @type t :: %__MODULE__{
            left: integer(),
            right: integer(),
            top: integer(),
            bottom: integer()
          }

    defstruct [:left, :right, :top, :bottom]
  end
end
