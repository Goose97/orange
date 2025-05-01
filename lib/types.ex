defmodule Orange.Rect do
  @moduledoc false

  defstruct [:children, attributes: []]
end

defmodule Orange.CustomComponent do
  @moduledoc false

  defstruct [:module, :children, :render_result, :ref, attributes: []]
end

defmodule Orange.RawText do
  @moduledoc false

  defstruct [:direction, :content]

  def build({:raw_text, direction, content}) do
    content =
      if(is_list(content), do: content, else: [content])
      |> Enum.map(fn
        text when is_binary(text) -> %{text: text}
        %{text: _} = v -> v
      end)

    %__MODULE__{direction: direction, content: content}
  end

  def length(%__MODULE__{content: content}) do
    content
    |> Enum.map(fn %{text: text} -> String.length(text) end)
    |> Enum.sum()
  end
end

defmodule Orange.Cursor do
  @moduledoc false

  defstruct [:x, :y]
end
