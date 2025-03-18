defmodule Orange.Test.Snapshot do
  @moduledoc """
  A snapshot of a terminal buffer captured during a test.
  """

  @type t :: %__MODULE__{buffer: Orange.Renderer.Buffer}

  defstruct [:buffer]

  @doc """
  Returns the content of the snapshot as a string.
  """
  def content(%__MODULE__{buffer: buffer}, opts \\ []),
    do: Orange.Renderer.Buffer.to_string(buffer, opts)
end
