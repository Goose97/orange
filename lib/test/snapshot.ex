defmodule Orange.Test.Snapshot do
  @type t :: %__MODULE__{buffer: Orange.Renderer.Buffer}

  defstruct [:buffer]

  def content(%__MODULE__{buffer: buffer}), do: Orange.Renderer.Buffer.to_string(buffer)
end
