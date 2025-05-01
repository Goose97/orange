defmodule Orange.Renderer.FooterTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "footer" do
    test ":footer is a string" do
      element =
        rect style: [border: true, width: "100%"], footer: "Footer" do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │foobar-------│
             └───────Footer┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test ":footer is a map with text is a string" do
      element =
        rect style: [border: true, width: "100%", flex_direction: :column],
             footer: %{text: "Footer", offset: 3} do
          "foo"
          "bar"
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─────────────┐
             │foo----------│
             │bar----------│
             └────Footer───┘
             ---------------
             ---------------\
             """
    end

    test ":footer is a raw text" do
      element =
        rect style: [border: true, width: "100%", flex_direction: :column],
             footer: %{text: {:raw_text, :row, "Footer"}, offset: 3} do
          "foo"
          "bar"
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─────────────┐
             │foo----------│
             │bar----------│
             └────Footer───┘
             ---------------
             ---------------\
             """
    end

    test ":footer with center alignment" do
      element =
        rect style: [border: true, width: "100%"],
             footer: %{text: "Footer", align: :center} do
          "foo"
          "bar"
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─────────────┐
             │foobar-------│
             └───Footer────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test ":footer with left alignment" do
      element =
        rect style: [border: true, width: "100%"],
             footer: %{text: "Footer", align: :left, offset: 1} do
          "foo"
          "bar"
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─────────────┐
             │foobar-------│
             └─Footer──────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test ":footer is an element" do
      footer =
        rect style: [color: :red] do
          "Hello World"
        end

      element =
        rect style: [border: true, width: "100%"], footer: footer do
          "foo"
          "bar"
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})

      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─────────────┐
             │foobar-------│
             └──Hello World┘
             ---------------
             ---------------
             ---------------\
             """

      Enum.each(3..13, fn x ->
        assert Buffer.get_color(buffer, x, 2) == :red
      end)
    end

    test ":footer is a map with text is an element" do
      footer =
        rect style: [color: :red] do
          "Hello World"
        end

      element =
        rect style: [border: true, width: "100%"], footer: %{text: footer, offset: 1} do
          "foo"
          "bar"
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})

      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─────────────┐
             │foobar-------│
             └─Hello World─┘
             ---------------
             ---------------
             ---------------\
             """

      Enum.each(2..12, fn x ->
        assert Buffer.get_color(buffer, x, 2) == :red
      end)
    end

    test ":footer is a map with text is an element with center alignment" do
      footer =
        rect style: [color: :red] do
          "Hello"
        end

      element =
        rect style: [border: true, width: "100%"], footer: %{text: footer, align: :center} do
          "foo"
          "bar"
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})

      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─────────────┐
             │foobar-------│
             └────Hello────┘
             ---------------
             ---------------
             ---------------\
             """

      # Check that the color is applied to the centered text
      Enum.each(5..9, fn x ->
        assert Buffer.get_color(buffer, x, 2) == :red
      end)
    end

    test ":footer is a map with text is an element with left alignment" do
      footer =
        rect style: [color: :red] do
          "Hello"
        end

      element =
        rect style: [border: true, width: "100%"],
             footer: %{text: footer, align: :left, offset: 1} do
          "foo"
          "bar"
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})

      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─────────────┐
             │foobar-------│
             └─Hello───────┘
             ---------------
             ---------------
             ---------------\
             """

      # Check that the color is applied to the right-aligned text
      Enum.each(2..6, fn x ->
        assert Buffer.get_color(buffer, x, 2) == :red
      end)
    end
  end
end
