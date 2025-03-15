defmodule Orange.Renderer.TitleTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "title" do
    test ":title is a string" do
      element =
        rect style: [border: true, width: "100%"], title: "Title" do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌Title────────┐
             │foobar-------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test ":title is a map with text is a string" do
      element =
        rect style: [border: true, width: "100%", flex_direction: :column],
             title: %{text: "Title", offset: 3} do
          "foo"
          "bar"
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌───Title─────┐
             │foo----------│
             │bar----------│
             └─────────────┘
             ---------------
             ---------------\
             """
    end

    test ":title with center alignment" do
      element =
        rect style: [border: true, width: "100%"],
             title: %{text: "Title", align: :center, offset: 2} do
          "foo"
          "bar"
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌──────Title──┐
             │foobar-------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test ":title with right alignment" do
      element =
        rect style: [border: true, width: "100%"],
             title: %{text: "Title", align: :right, offset: 1} do
          "foo"
          "bar"
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌───────Title─┐
             │foobar-------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test ":title is an element" do
      title =
        rect style: [color: :red] do
          "Hello World"
        end

      element =
        rect style: [border: true, width: "100%"], title: title do
          "foo"
          "bar"
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})

      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌Hello World──┐
             │foobar-------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """

      Enum.each(1..10, fn x ->
        assert Buffer.get_color(buffer, x, 0) == :red
      end)
    end

    test ":title is a map with text is an element" do
      title =
        rect style: [color: :red] do
          "Hello World"
        end

      element =
        rect style: [border: true, width: "100%"], title: %{text: title, offset: 1} do
          "foo"
          "bar"
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})

      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌─Hello World─┐
             │foobar-------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """

      Enum.each(2..11, fn x ->
        assert Buffer.get_color(buffer, x, 0) == :red
      end)
    end

    test ":title is a map with text is an element with center alignment" do
      title =
        rect style: [color: :red] do
          "Hello"
        end

      element =
        rect style: [border: true, width: "100%"], title: %{text: title, align: :center} do
          "foo"
          "bar"
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})

      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌────Hello────┐
             │foobar-------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """

      # Check that the color is applied to the centered text
      Enum.each(5..9, fn x ->
        assert Buffer.get_color(buffer, x, 0) == :red
      end)
    end

    test ":title is a map with text is an element with right alignment" do
      title =
        rect style: [color: :red] do
          "Hello"
        end

      element =
        rect style: [border: true, width: "100%"],
             title: %{text: title, align: :right, offset: 1} do
          "foo"
          "bar"
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})

      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌───────Hello─┐
             │foobar-------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """

      # Check that the color is applied to the right-aligned text
      Enum.each(8..12, fn x ->
        assert Buffer.get_color(buffer, x, 0) == :red
      end)
    end
  end
end
