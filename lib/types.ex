defmodule Orange.Rect do
  @moduledoc false

  # :children must be a list of rects or lines
  defstruct [:children, attributes: []]
end

defmodule Orange.CustomComponent do
  @moduledoc false

  defstruct [:module, :children, :ref, attributes: []]
end

defmodule Orange.Cursor do
  @moduledoc false

  defstruct [:x, :y]
end
