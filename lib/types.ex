defmodule Orange.Rect do
  @moduledoc false

  defstruct [:children, attributes: []]
end

defmodule Orange.CustomComponent do
  @moduledoc false

  defstruct [:module, :children, :ref, attributes: []]
end

defmodule Orange.RawText do
  @moduledoc false

  defstruct [:direction, :content]
end

defmodule Orange.Cursor do
  @moduledoc false

  defstruct [:x, :y]
end
