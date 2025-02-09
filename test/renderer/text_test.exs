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

  describe "line wrap" do
    test "width is enough" do
      element =
        rect style: [width: 10, height: 3, border: true] do
          rect do
            "foo bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────┐-----
             │foo bar-│-----
             └────────┘-----
             ---------------
             ---------------
             ---------------\
             """
    end

    test "width is not enough, split by word basis" do
      element =
        rect style: [width: 7, height: 5, border: true] do
          rect do
            "foo bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────┐--------
             │foo--│--------
             │bar--│--------
             │-----│--------
             └─────┘--------
             ---------------\
             """
    end

    test "width is enough, with leading whitespaces" do
      element =
        rect style: [width: 12, height: 5, border: true] do
          rect do
            "  foo bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 18, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────┐------
             │  foo bar-│------
             │----------│------
             │----------│------
             └──────────┘------
             ------------------\
             """
    end

    test "width is not enough, with leading whitespaces" do
      element =
        rect style: [width: 10, height: 5, border: true] do
          rect do
            "  foo bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 18, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────┐--------
             │  foo---│--------
             │bar-----│--------
             │--------│--------
             └────────┘--------
             ------------------\
             """
    end

    test "multiple whitespaces between words" do
      # If the text is split into lines, these whitespaces got trimmed
      element =
        rect style: [width: 10, height: 5, border: true] do
          rect do
            "  foo    bar   baz"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 18, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────┐--------
             │  foo---│--------
             │bar-----│--------
             │baz-----│--------
             └────────┘--------
             ------------------\
             """
    end

    test "preserves trailing whitespaces" do
      # If the text is split into lines, these whitespaces got trimmed
      element =
        rect style: [width: 10, height: 5, border: true] do
          rect do
            "  foo    bar   baz   "
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 18, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────┐--------
             │  foo---│--------
             │bar-----│--------
             │baz   --│--------
             └────────┘--------
             ------------------\
             """
    end

    test "disable line wrap" do
      element =
        rect style: [width: 7, height: 5, border: true] do
          rect style: [line_wrap: false] do
            "foo bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────┐--------
             │foo bar-------
             │-----│--------
             │-----│--------
             └─────┘--------
             ---------------\
             """
    end
  end
end
