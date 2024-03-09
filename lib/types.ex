defmodule Orange.Rect do
  # :children must be a list of rects or lines
  defstruct [:children, attributes: []]
end

defmodule Orange.Line do
  # :children must be a list of spans
  defstruct [:children, attributes: []]
end

defmodule Orange.Span do
  # :children must be a text
  defstruct [:children, attributes: []]
end

defmodule Orange.CustomComponent do
  defstruct [:module, :children, :ref, attributes: []]
end

defmodule Orange.Cursor do
  defstruct [:x, :y]
end
