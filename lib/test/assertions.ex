defmodule Orange.Test.Assertions do
  @moduledoc """
  Orange test assertion functions.

  This module provides assertion functions for testing Orange terminal UI components.
  It includes functions to verify content, colors, and text modifiers in the terminal buffer.
  """

  require ExUnit.Assertions

  alias Orange.Renderer.Buffer

  @doc """
  Asserts that the string representation of the buffer matches the expected content.

  ## Parameters

    * snapshot - A snapshot containing the buffer to test
    * expected - The expected string content to match against

  ## Example

      assert_content(snapshot, \"\"\"
      Hello
      World
      \"\"\")
  """
  def assert_content(%Orange.Test.Snapshot{buffer: buffer}, expected) do
    content = Buffer.to_string(buffer)
    ExUnit.Assertions.assert(content == expected)
  end

  @doc """
  Asserts that cells have the specified foreground color.

  Can check a single coordinate or a range of coordinates.

  ## Parameters

    * snapshot - A snapshot containing the buffer to test
    * x - X coordinate or range of X coordinates
    * y - Y coordinate or range of Y coordinates
    * color - The expected foreground color

  ## Example

      # Check single coordinate
      assert_color(snapshot, 0, 0, :red)

      # Check range
      assert_color(snapshot, 0..2, 1, :blue)
      assert_color(snapshot, 0, 1..2, :blue)
  """
  def assert_color(snapshot, x, y, color) when is_struct(x, Range),
    do: Enum.each(x, fn idx -> assert_color(snapshot, idx, y, color) end)

  def assert_color(snapshot, x, y, color) when is_struct(y, Range),
    do: Enum.each(y, fn idx -> assert_color(snapshot, x, idx, color) end)

  def assert_color(%Orange.Test.Snapshot{buffer: buffer}, x, y, color)
      when is_integer(x) and is_integer(y),
      do: ExUnit.Assertions.assert(Buffer.get_color(buffer, x, y) == color)

  @doc """
  Asserts that cells have the specified background color.

  Can check a single coordinate or a range of coordinates.

  ## Parameters

    * snapshot - A snapshot containing the buffer to test
    * x - X coordinate or range of X coordinates
    * y - Y coordinate or range of Y coordinates
    * color - The expected background color

  ## Example

      # Check single coordinate
      assert_background_color(snapshot, 1, 1, :green)

      # Check range
      assert_background_color(snapshot, 0..2, 0, :yellow)
      assert_background_color(snapshot, 0, 0..3, :yellow)
  """
  def assert_background_color(snapshot, x, y, color) when is_struct(x, Range),
    do: Enum.each(x, fn idx -> assert_background_color(snapshot, idx, y, color) end)

  def assert_background_color(snapshot, x, y, color) when is_struct(y, Range),
    do: Enum.each(y, fn idx -> assert_background_color(snapshot, x, idx, color) end)

  def assert_background_color(%Orange.Test.Snapshot{buffer: buffer}, x, y, color),
    do: ExUnit.Assertions.assert(Buffer.get_background_color(buffer, x, y) == color)

  @doc """
  Asserts that cells have the specified text modifiers.

  Can check for a single modifier, multiple modifiers, or modifiers across a range.

  ## Parameters

    * snapshot - A snapshot containing the buffer to test
    * x - X coordinate or range of X coordinates
    * y - Y coordinate or range of Y coordinates
    * modifiers - A single modifier atom or list of modifier atoms to check for

  ## Example

      # Check single modifier
      assert_text_modifiers(snapshot, 0, 0, :bold)

      # Check multiple modifiers
      assert_text_modifiers(snapshot, 1, 1, [:bold, :italic])

      # Check range
      assert_text_modifiers(snapshot, 0..2, 0, :underline)
      assert_text_modifiers(snapshot, 0, 0..2, :underline)
  """
  def assert_text_modifiers(snapshot, x, y, modifiers)
      when is_list(modifiers),
      do: Enum.each(modifiers, fn modifier -> assert_text_modifiers(snapshot, x, y, modifier) end)

  def assert_text_modifiers(snapshot, x, y, modifier) when is_struct(x, Range),
    do: Enum.each(x, fn idx -> assert_text_modifiers(snapshot, idx, y, modifier) end)

  def assert_text_modifiers(snapshot, x, y, modifier) when is_struct(y, Range),
    do: Enum.each(y, fn idx -> assert_text_modifiers(snapshot, x, idx, modifier) end)

  def assert_text_modifiers(%Orange.Test.Snapshot{buffer: buffer}, x, y, modifier)
      when is_atom(modifier),
      do: ExUnit.Assertions.assert(modifier in Buffer.get_modifiers(buffer, x, y))
end
