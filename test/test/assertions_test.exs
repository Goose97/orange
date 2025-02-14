defmodule Orange.Test.AssertionsTest do
  use ExUnit.Case, async: true

  alias Orange.Test.{Assertions, Snapshot}
  alias Orange.Renderer.{Buffer, Cell}

  describe "content assertions" do
    test "assert_content matches expected string representation" do
      buffer = Buffer.new({3, 2})
      buffer = Buffer.write_string(buffer, {0, 0}, "abc", :horizontal)
      buffer = Buffer.write_string(buffer, {0, 1}, "def", :horizontal)

      snapshot = %Snapshot{buffer: buffer}

      expected =
        """
        abc
        def\
        """

      Assertions.assert_content(snapshot, expected)
    end
  end

  describe "color assertions" do
    test "assert_color with single coordinate" do
      buffer = Buffer.new({2, 2})
      buffer = Buffer.write_cell(buffer, {0, 0}, %Cell{foreground: :red})
      snapshot = %Snapshot{buffer: buffer}

      Assertions.assert_color(snapshot, 0, 0, :red)
    end

    test "assert_color with range" do
      buffer = Buffer.new({3, 2})
      buffer = Buffer.write_string(buffer, {0, 0}, "   ", :horizontal, color: :blue)
      buffer = Buffer.write_string(buffer, {0, 1}, "   ", :horizontal, color: :blue)
      snapshot = %Snapshot{buffer: buffer}

      Assertions.assert_color(snapshot, 0..2, 0, :blue)
      Assertions.assert_color(snapshot, 0, 0..1, :blue)
      Assertions.assert_color(snapshot, 0..2, 0..1, :blue)
    end
  end

  describe "background color assertions" do
    test "assert_background_color with single coordinate" do
      buffer = Buffer.new({2, 2})
      buffer = Buffer.write_cell(buffer, {1, 1}, %Cell{background: :green})
      snapshot = %Snapshot{buffer: buffer}

      Assertions.assert_background_color(snapshot, 1, 1, :green)
    end

    test "assert_background_color with range" do
      buffer = Buffer.new({3, 2})
      buffer = Buffer.write_string(buffer, {0, 0}, "   ", :horizontal, background_color: :yellow)
      buffer = Buffer.write_string(buffer, {0, 1}, "   ", :horizontal, background_color: :yellow)
      snapshot = %Snapshot{buffer: buffer}

      Assertions.assert_background_color(snapshot, 0..2, 0, :yellow)
      Assertions.assert_background_color(snapshot, 0, 0..1, :yellow)
      Assertions.assert_background_color(snapshot, 0..2, 0..1, :yellow)
    end
  end

  describe "text modifier assertions" do
    test "assert_text_modifiers with single modifier" do
      buffer = Buffer.new({2, 2})
      buffer = Buffer.write_cell(buffer, {0, 0}, %Cell{modifiers: [:bold]})
      snapshot = %Snapshot{buffer: buffer}

      Assertions.assert_text_modifiers(snapshot, 0, 0, :bold)
    end

    test "assert_text_modifiers with multiple modifiers" do
      buffer = Buffer.new({2, 2})
      buffer = Buffer.write_cell(buffer, {1, 1}, %Cell{modifiers: [:bold, :italic]})
      snapshot = %Snapshot{buffer: buffer}

      Assertions.assert_text_modifiers(snapshot, 1, 1, [:bold, :italic])
    end

    test "assert_text_modifiers with range" do
      buffer = Buffer.new({3, 2})

      buffer =
        Buffer.write_string(buffer, {0, 0}, "   ", :horizontal,
          text_modifiers: [:bold, :underline]
        )

      buffer =
        Buffer.write_string(buffer, {0, 1}, "   ", :horizontal, text_modifiers: [:underline])

      snapshot = %Snapshot{buffer: buffer}

      Assertions.assert_text_modifiers(snapshot, 0..2, 0, [:bold, :underline])
      Assertions.assert_text_modifiers(snapshot, 0, 0..1, :underline)
      Assertions.assert_text_modifiers(snapshot, 0..2, 0..1, :underline)
    end
  end
end
