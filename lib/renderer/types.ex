defmodule Orange.Renderer.Cell do
  @moduledoc false

  defstruct [:foreground, :background, modifiers: [], character: " "]
end

defmodule Orange.Renderer.Box do
  @moduledoc false

  # Boxes are builing blocks of the render tree. A box children can either be:
  # - A list of boxes
  # - A single text

  @type position ::
          {:fixed, top :: non_neg_integer, right :: non_neg_integer, bottom :: non_neg_integer,
           left :: non_neg_integer}
          | nil

  @type t :: %__MODULE__{
          children: [t] | binary,
          padding:
            {top :: non_neg_integer, right :: non_neg_integer, bottom :: non_neg_integer,
             left :: non_neg_integer},
          border: {top :: boolean, right :: boolean, bottom :: boolean, left :: boolean} | nil,
          style: [text_modifiers: [atom], background_color: :atom, color: :atom],
          width: non_neg_integer | nil,
          height: non_neg_integer | nil,
          layout_direction: :row | :column,
          scroll: {x :: non_neg_integer, y :: non_neg_integer},
          position: position(),
          outer_area: Orange.Renderer.Area.t(),
          inner_area: Orange.Renderer.Area.t()
        }
  defstruct [
    :children,
    :padding,
    :border,
    :style,
    :width,
    :height,
    :layout_direction,
    :scroll,
    :position,
    :outer_area,
    :inner_area,
    :title
  ]
end

defmodule Orange.Renderer.Area do
  @moduledoc false

  @type t :: %__MODULE__{
          x: non_neg_integer,
          y: non_neg_integer,
          width: non_neg_integer,
          height: non_neg_integer
        }
  defstruct [:x, :y, :width, :height]
end

defmodule Orange.Renderer.LayoutBox do
  @moduledoc false

  defstruct [:width, :height, :x, :y, :border, :text]

  defmodule Border do
    defstruct [:left, :right, :top, :bottom]
  end

  defmodule Tree do
    defstruct [:node, :children]
  end
end
