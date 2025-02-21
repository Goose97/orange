defmodule Orange.Renderer.TextTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "text modifiers" do
    test "renders text with modifiers" do
      element =
        rect style: [border: true, width: 10, text_modifiers: [:bold]] do
          "foo"
        end

      {buffer, _} = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Buffer.to_string(buffer)

      assert screen == """
             ┌────────┐-----
             │foo-----│-----
             └────────┘-----
             ---------------
             ---------------
             ---------------\
             """

      Enum.each(1..3, fn x ->
        assert :bold in Buffer.get_modifiers(buffer, x, 1)
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
        |> elem(0)
        |> Buffer.to_string()

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
        |> elem(0)
        |> Buffer.to_string()

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
        |> elem(0)
        |> Buffer.to_string()

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
        |> elem(0)
        |> Buffer.to_string()

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
        |> elem(0)
        |> Buffer.to_string()

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
        |> elem(0)
        |> Buffer.to_string()

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
        |> elem(0)
        |> Buffer.to_string()

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

  test "multi codepoints char" do
    element =
      rect style: [width: 15, height: 3, border: true] do
        rect do
          "🭬 foo"
          "bar"
        end
      end

    screen =
      element
      |> Orange.Renderer.render(%{width: 15, height: 6})
      |> elem(0)
      |> Buffer.to_string()

    assert screen == """
           ┌─────────────┐
           │🭬 foobar-----│
           └─────────────┘
           ---------------
           ---------------
           ---------------\
           """
  end

  test "center text" do
    element =
      rect style: [
             width: "100%",
             height: "100%",
             border: true,
             display: :flex,
             justify_content: :center,
             align_items: :center
           ] do
        "foo"
      end

    screen =
      element
      |> Orange.Renderer.render(%{width: 15, height: 7})
      |> elem(0)
      |> Buffer.to_string()

    assert screen == """
           ┌─────────────┐
           │-------------│
           │-------------│
           │-----foo-----│
           │-------------│
           │-------------│
           └─────────────┘\
           """
  end
end
