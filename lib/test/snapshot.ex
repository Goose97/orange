defmodule Orange.Test.Snapshot do
  @type t :: %__MODULE__{buffer: Orange.Renderer.Buffer}

  defstruct [:buffer]
end
