defmodule Orange.RendererTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "rect element" do
    test "renders a plain rect" do
      element =
        rect do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

      assert screen == """
             ┌───┐----------
             │foo│----------
             │bar│----------
             └───┘----------
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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        assert Buffer.get_color(buffer, x, y) == :red
        assert :bold in Buffer.get_modifiers(buffer, x, y)
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
        assert Buffer.get_color(buffer, x, y) == :blue
        assert :italic in Buffer.get_modifiers(buffer, x, y)
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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

      assert screen == """
             ┌───┐----------
             │foo│----------
             └bar┘----------
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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

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
        |> Buffer.to_string()

      assert screen == """
             111------------
             2┌───────────┐-
             3│foo--------│-
             4└───────────┘-
             555------------\
             """
    end
  end

  describe "background text" do
    test "takes a string" do
      element =
        rect style: [width: 10, height: 4, border: true], background_text: "|" do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Buffer.to_string()

      assert screen == """
             ┌────────┐-----
             │foo|||||│-----
             │||||||||│-----
             └────────┘-----
             ---------------\
             """
    end

    test "takes a map" do
      element =
        rect style: [width: 10, height: 4, border: true],
             background_text: %{text: "|", color: :red, text_modifiers: [:bold]} do
          "foo"
        end

      buffer =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})

      Enum.each(1..8, fn col ->
        Enum.each(1..2, fn row ->
          if row != 1 or col not in [1, 2, 3] do
            assert Buffer.get_color(buffer, col, row) == :red
            assert :bold in Buffer.get_modifiers(buffer, col, row)
          end
        end)
      end)

      assert Buffer.to_string(buffer) == """
             ┌────────┐-----
             │foo|||||│-----
             │||||||||│-----
             └────────┘-----
             ---------------\
             """
    end
  end
end
