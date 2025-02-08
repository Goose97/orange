defmodule Orange.Renderer.TextTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.RendererTestHelper, as: Helper

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
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌Title────────┐
             │foobar-------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test ":title is a map" do
      element =
        rect style: [border: true, width: "100%", flex_direction: :column],
             title: %{text: "Title", color: :red, text_modifiers: [:bold], offset: 3} do
          "foo"
          "bar"
        end

      buffer = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Orange.Renderer.Buffer.to_string(buffer)

      assert screen == """
             ┌───Title─────┐
             │foo----------│
             │bar----------│
             └─────────────┘
             ---------------
             ---------------\
             """

      Enum.each(4..8, fn x ->
        assert Helper.get_color(buffer, x, 0) == :red
        assert :bold in Helper.get_modifiers(buffer, x, 0)
      end)
    end
  end

  describe "text modifiers" do
    test "renders text with modifiers" do
      element =
        rect style: [border: true, width: 10, text_modifiers: [:bold]] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Orange.Renderer.Buffer.to_string(buffer)

      assert screen == """
             ┌────────┐-----
             │foo-----│-----
             └────────┘-----
             ---------------
             ---------------
             ---------------\
             """

      Enum.each(1..3, fn x ->
        assert :bold in Helper.get_modifiers(buffer, x, 1)
      end)
    end
  end
end
