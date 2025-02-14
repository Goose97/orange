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

  def assert_color(snapshot, x, y, color) when is_struct(x, Range),
    do: Enum.each(x, fn idx -> assert_color(snapshot, idx, y, color) end)

  def assert_color(snapshot, x, y, color) when is_struct(y, Range),
    do: Enum.each(y, fn idx -> assert_color(snapshot, x, idx, color) end)

  def assert_color(%Orange.Test.Snapshot{buffer: buffer}, x, y, color)
      when is_integer(x) and is_integer(y),
      do: ExUnit.Assertions.assert(Helper.get_color(buffer, x, y) == color)

  def assert_background_color(snapshot, x, y, color) when is_struct(x, Range),
    do: Enum.each(x, fn idx -> assert_background_color(snapshot, idx, y, color) end)

  def assert_background_color(snapshot, x, y, color) when is_struct(y, Range),
    do: Enum.each(y, fn idx -> assert_background_color(snapshot, x, idx, color) end)

  def assert_background_color(%Orange.Test.Snapshot{buffer: buffer}, x, y, color),
    do: ExUnit.Assertions.assert(Helper.get_background_color(buffer, x, y) == color)

  def assert_text_modifiers(snapshot, x, y, modifiers)
      when is_list(modifiers),
      do: Enum.each(modifiers, fn modifier -> assert_text_modifiers(snapshot, x, y, modifier) end)

  def assert_text_modifiers(snapshot, x, y, modifier) when is_struct(x, Range),
    do: Enum.each(x, fn idx -> assert_text_modifiers(snapshot, idx, y, modifier) end)

  def assert_text_modifiers(snapshot, x, y, modifier) when is_struct(y, Range),
    do: Enum.each(y, fn idx -> assert_text_modifiers(snapshot, x, idx, modifier) end)

  def assert_text_modifiers(%Orange.Test.Snapshot{buffer: buffer}, x, y, modifier)
      when is_atom(modifier),
      do: ExUnit.Assertions.assert(modifier in Helper.get_modifiers(buffer, x, y))
end
