defmodule Orange.Renderer.RawTextTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "row direction" do
    test "single simple text" do
      element =
        rect style: [width: 10, height: 4, border: true] do
          %Orange.RawText{content: "foo", direction: :row}
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 5})

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │foo-----│-----
             │--------│-----
             └────────┘-----
             ---------------\
             """
    end

    test "list of simple texts" do
      element =
        rect style: [width: 10, height: 4, border: true] do
          %Orange.RawText{content: ["foo", "bar"], direction: :row}
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 5})

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │foobar--│-----
             │--------│-----
             └────────┘-----
             ---------------\
             """
    end

    test "single complex text" do
      element =
        rect style: [width: 10, height: 4, border: true] do
          %Orange.RawText{
            content: %{text: "foo", background_color: :red, color: :yellow},
            direction: :row
          }
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 5})

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │foo-----│-----
             │--------│-----
             └────────┘-----
             ---------------\
             """

      Enum.each(1..3, fn x ->
        assert Buffer.get_background_color(buffer, x, 1) == :red
        assert Buffer.get_color(buffer, x, 1) == :yellow
      end)
    end

    test "list of complex texts" do
      element =
        rect style: [width: 10, height: 4, border: true] do
          %Orange.RawText{
            content: [
              %{text: "foo", background_color: :red, color: :yellow},
              %{text: "bar", background_color: :yellow, color: :red}
            ],
            direction: :row
          }
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 5})

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │foobar--│-----
             │--------│-----
             └────────┘-----
             ---------------\
             """

      Enum.each(1..3, fn x ->
        assert Buffer.get_background_color(buffer, x, 1) == :red
        assert Buffer.get_color(buffer, x, 1) == :yellow
      end)

      Enum.each(4..6, fn x ->
        assert Buffer.get_background_color(buffer, x, 1) == :yellow
        assert Buffer.get_color(buffer, x, 1) == :red
      end)
    end
  end

  describe "vertical direction" do
    test "single simple text" do
      element =
        rect style: [width: 10, height: 6, border: true] do
          %Orange.RawText{content: "foo", direction: :column}
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 7})

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │f-------│-----
             │o-------│-----
             │o-------│-----
             │--------│-----
             └────────┘-----
             ---------------\
             """
    end

    test "list of simple texts" do
      element =
        rect style: [width: 10, height: 8, border: true] do
          %Orange.RawText{content: ["foo", "bar"], direction: :column}
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 10})

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │f-------│-----
             │o-------│-----
             │o-------│-----
             │b-------│-----
             │a-------│-----
             │r-------│-----
             └────────┘-----
             ---------------
             ---------------\
             """
    end

    test "single complex text" do
      element =
        rect style: [width: 10, height: 6, border: true] do
          %Orange.RawText{
            content: %{text: "foo", background_color: :red, color: :yellow},
            direction: :column
          }
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 8})

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │f-------│-----
             │o-------│-----
             │o-------│-----
             │--------│-----
             └────────┘-----
             ---------------
             ---------------\
             """

      Enum.each(1..3, fn y ->
        assert Buffer.get_background_color(buffer, 1, y) == :red
        assert Buffer.get_color(buffer, 1, y) == :yellow
      end)
    end

    test "list of complex texts" do
      element =
        rect style: [width: 10, height: 8, border: true] do
          %Orange.RawText{
            content: [
              %{text: "foo", background_color: :red, color: :yellow},
              %{text: "bar", background_color: :yellow, color: :red}
            ],
            direction: :column
          }
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 10})

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │f-------│-----
             │o-------│-----
             │o-------│-----
             │b-------│-----
             │a-------│-----
             │r-------│-----
             └────────┘-----
             ---------------
             ---------------\
             """

      Enum.each(1..3, fn y ->
        assert Buffer.get_background_color(buffer, 1, y) == :red
        assert Buffer.get_color(buffer, 1, y) == :yellow
      end)

      Enum.each(4..6, fn y ->
        assert Buffer.get_background_color(buffer, 1, y) == :yellow
        assert Buffer.get_color(buffer, 1, y) == :red
      end)
    end
  end
end
