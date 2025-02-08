defmodule Orange.RendererTest do
  use ExUnit.Case
  import Orange.Macro

  ############
  # render/2 #
  ############
  describe "rect element" do
    test "renders a plain rect" do
      element =
        rect do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             foo------------
             ---------------
             ---------------
             ---------------
             ---------------\
             """
    end

    test "renders with flex direction" do
      element =
        rect style: [border: true, flex_direction: :row] do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────┐-------
             │foobar│-------
             └──────┘-------
             ---------------
             ---------------\
             """

      element =
        rect style: [border: true, flex_direction: :column] do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │foo----------│
             │bar----------│
             └─────────────┘
             ---------------\
             """
    end

    test "renders with nested rects" do
      element =
        rect style: [border: true] do
          rect style: [border: true, height: 4] do
            "foo"
          end

          rect style: [border: true, width: 10] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌───────────────┐---
             │┌───┐┌────────┐│---
             ││foo││bar-----││---
             ││---││--------││---
             │└───┘└────────┘│---
             └───────────────┘---
             --------------------
             --------------------
             --------------------
             --------------------\
             """

      element =
        rect style: [border: true, flex_direction: :row] do
          rect style: [border: true] do
            rect style: [border: true, width: 7] do
              "foo"
            end

            rect style: [border: true, width: 12] do
              "bar"
            end
          end

          rect style: [border: true, width: 10] do
            "baz"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 35, height: 12})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌───────────────────────────────┐--
             │┌───────────────────┐┌────────┐│--
             ││┌─────┐┌──────────┐││baz-----││--
             │││foo--││bar-------│││--------││--
             ││└─────┘└──────────┘││--------││--
             │└───────────────────┘└────────┘│--
             └───────────────────────────────┘--
             -----------------------------------
             -----------------------------------
             -----------------------------------
             -----------------------------------
             -----------------------------------\
             """
    end
  end

  describe "style inheritance" do
    test "inherits styles from ancestors" do
      element =
        rect style: [color: :red, text_modifiers: [:bold]] do
          rect do
            "foo"
          end
        end

      buffer = Orange.Renderer.render(element, %{width: 10, height: 3})

      Enum.each([{0, 0}, {1, 0}, {2, 0}], fn {x, y} ->
        assert get_color(buffer, x, y) == :red
        assert :bold in get_modifiers(buffer, x, y)
      end)
    end

    test "children styles have higher precedence over ancestor styles" do
      element =
        rect style: [color: :red, text_modifiers: [:bold]] do
          rect style: [color: :blue, text_modifiers: [:italic]] do
            "foo"
          end
        end

      buffer = Orange.Renderer.render(element, %{width: 10, height: 3})

      Enum.each([{0, 0}, {1, 0}, {2, 0}], fn {x, y} ->
        assert get_color(buffer, x, y) == :blue
        assert :italic in get_modifiers(buffer, x, y)
      end)
    end
  end

  describe "content overflow" do
    test "single child, parent no padding" do
      element =
        rect style: [width: 6, border: true] do
          "foobar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────┐---------
             │foobar--------
             └────┘---------
             ---------------
             ---------------\
             """
    end

    test "single child, parent with padding" do
      element =
        rect style: [width: 6, padding: 1, border: true] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────┐---------
             │----│---------
             │-foo│---------
             │----│---------
             └────┘---------
             ---------------
             ---------------\
             """
    end

    test "vertical overflow" do
      element =
        rect style: [height: 3, border: true, flex_direction: :column] do
          "foo"
          "bar"
          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │foo----------│
             └bar──────────┘
             -baz-----------
             ---------------
             ---------------
             ---------------\
             """
    end
  end

  describe "content scroll" do
    test "vertical scroll" do
      element =
        rect style: [width: "100%", height: 3, flex_direction: :column], scroll_y: 1 do
          rect style: [flex_direction: :column] do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             bar------------
             baz------------
             qux------------
             ---------------
             ---------------\
             """

      element =
        rect style: [
               width: "100%",
               height: 5,
               padding: {0, 1},
               border: true,
               flex_direction: :column
             ],
             scroll_y: 2 do
          rect style: [width: 8, border: true, flex_direction: :column] do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │-│bar---│----│
             │-└──────┘----│
             │-baz---------│
             └─────────────┘\
             """
    end

    test "vertical scroll in nested children" do
      element =
        rect style: [
               width: "100%",
               height: 5,
               padding: {0, 1},
               border: true,
               flex_direction: :column
             ] do
          rect style: [width: 8, height: 3, border: true, flex_direction: :column], scroll_y: 1 do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │-┌──────┐----│
             │-│bar---│----│
             │-└──────┘----│
             └─baz─────────┘
             --qux----------
             ---------------\
             """
    end

    test "vertical over scroll" do
      element =
        rect style: [width: "100%", height: 3, flex_direction: :column], scroll_y: 4 do
          rect style: [flex_direction: :column] do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ---------------
             ---------------
             ---------------
             ---------------
             ---------------\
             """
    end

    test "horizontal scroll" do
      element =
        rect style: [width: 3, height: "100%", flex_direction: :column], scroll_x: 1 do
          rect style: [flex_direction: :column] do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             oo-------------
             ar-------------
             az-------------
             ux-------------
             ---------------\
             """

      element =
        rect style: [
               width: 10,
               height: "100%",
               padding: {0, 1},
               border: true,
               flex_direction: :column
             ],
             scroll_x: 2 do
          rect style: [border: true, flex_direction: :column] do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────┐-----
             │-───┐---│-----
             │-oo-│---│-----
             │-ar-│---│-----
             │-───┘---│-----
             │-z------│-----
             └────────┘-----\
             """
    end

    test "horizontal scroll with nested children" do
      element =
        rect style: [
               width: 10,
               height: "100%",
               padding: {0, 1},
               border: true,
               flex_direction: :column
             ] do
          rect style: [border: true, flex_direction: :column], scroll_x: 2 do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 9})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────┐-----
             │-┌────┐-│-----
             │-│o---│-│-----
             │-│r---│-│-----
             │-└────┘-│-----
             │-baz----│-----
             │-qux----│-----
             │--------│-----
             └────────┘-----\
             """
    end

    test "horizontal over scroll" do
      element =
        rect style: [width: 3, height: "100%"], scroll_x: 14 do
          rect do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ---------------
             ---------------
             ---------------
             ---------------
             ---------------\
             """
    end
  end

  describe "fixed position" do
    test "single fixed element" do
      element =
        rect style: [width: "100%", height: 3] do
          rect do
            "foo"
            "bar"
          end

          rect position: {:fixed, 4, 1, 1, 1}, style: [border: true] do
            "baz"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             foobar---------
             ---------------
             ---------------
             ---------------
             -┌───────────┐-
             -│baz--------│-
             -│-----------│-
             -│-----------│-
             -└───────────┘-
             ---------------\
             """
    end

    test "multiple fixed elements" do
      element =
        rect style: [width: "100%", height: 3] do
          rect do
            "foo"
            "bar"
          end

          rect position: {:fixed, 4, 1, 1, 1}, style: [border: true] do
            "baz"
          end

          rect position: {:fixed, 2, 4, 2, 0}, style: [border: true] do
            rect style: [padding: 1, flex_direction: :column] do
              "qux"
              "quux"
            end
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             foobar---------
             ---------------
             ┌─────────┐----
             │---------│----
             │-qux-----│──┐-
             │-quux----│--│-
             │---------│--│-
             └─────────┘--│-
             -└───────────┘-
             ---------------\
             """
    end

    test "root fixed element" do
      element =
        rect style: [border: true], position: {:fixed, 3, 3, 3, 3} do
          rect style: [flex_direction: :column] do
            "foo"
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ---------------
             ---------------
             ---------------
             ---┌───────┐---
             ---│foo----│---
             ---│bar----│---
             ---└───────┘---
             ---------------
             ---------------
             ---------------\
             """
    end

    test "width and height is ignored" do
      element =
        rect style: [width: 5, height: 5, border: true], position: {:fixed, 3, 3, 3, 3} do
          rect do
            "foo"
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ---------------
             ---------------
             ---------------
             ---┌───────┐---
             ---│foobar-│---
             ---│-------│---
             ---└───────┘---
             ---------------
             ---------------
             ---------------\
             """
    end

    test "overshadows layers behind" do
      element =
        rect style: [width: "100%", height: "100%", flex_direction: :column] do
          "111"
          "222"
          "333"
          "444"
          "555"

          rect position: {:fixed, 1, 1, 1, 1}, style: [border: true] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             111------------
             2┌───────────┐-
             3│foo--------│-
             4└───────────┘-
             555------------\
             """
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

  defp get_color(buffer, x, y) do
    cell = Orange.Renderer.Buffer.get_cell(buffer, {x, y})
    cell.foreground
  end

  defp get_background_color(buffer, x, y) do
    cell = Orange.Renderer.Buffer.get_cell(buffer, {x, y})
    cell.background
  end

  defp get_modifiers(buffer, x, y) do
    cell = Orange.Renderer.Buffer.get_cell(buffer, {x, y})
    cell.modifiers
  end
end
