defmodule Orange.Test.Assertions do
  @moduledoc """
  Orange test assertion functions.
  """

  require ExUnit.Assertions

  alias Orange.RendererTestHelper, as: Helper

  alias Orange.Renderer.Buffer

  def assert_content(%Orange.Test.Snapshot{buffer: buffer}, expected) do
    content = Buffer.to_string(buffer)
    ExUnit.Assertions.assert(content == expected)
  end

  def assert_color(%Orange.Test.Snapshot{buffer: buffer}, x, y, color),
    do: ExUnit.Assertions.assert(Helper.get_color(buffer, x, y) == color)

  def assert_background_color(%Orange.Test.Snapshot{buffer: buffer}, x, y, color),
    do: ExUnit.Assertions.assert(Helper.get_background_color(buffer, x, y) == color)

  def assert_text_modifiers(%Orange.Test.Snapshot{buffer: buffer}, x, y, modifiers)
      when is_list(modifiers),
      do: Enum.each(modifiers, fn modifier -> assert_text_modifiers(buffer, x, y, modifier) end)

  def assert_text_modifiers(%Orange.Test.Snapshot{buffer: buffer}, x, y, modifier),
    do: ExUnit.Assertions.assert(modifier in Helper.get_modifiers(buffer, x, y))
end
