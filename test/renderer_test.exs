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

    test "renders with direction" do
      element =
        rect style: [border: true], direction: :row do
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
        rect style: [border: true], direction: :column do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

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
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────┐---
             │┌───┐-----│---
             ││foo│-----│---
             ││---│-----│---
             │└───┘-----│---
             │┌────────┐│---
             ││bar-----││---
             │└────────┘│---
             └──────────┘---
             ---------------\
             """

      element =
        rect style: [border: true] do
          rect style: [border: true], direction: :row do
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
        |> Orange.Renderer.render(%{width: 25, height: 12})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────────────┐--
             │┌───────────────────┐│--
             ││┌─────┐┌──────────┐││--
             │││foo--││bar-------│││--
             ││└─────┘└──────────┘││--
             │└───────────────────┘│--
             │┌────────┐-----------│--
             ││baz-----│-----------│--
             │└────────┘-----------│--
             └─────────────────────┘--
             -------------------------
             -------------------------\
             """
    end
  end

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
             │foo----------│
             │bar----------│
             └─────────────┘
             ---------------
             ---------------\
             """
    end

    test ":title is a map" do
      element =
        rect style: [border: true, width: "100%"],
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
        assert get_color(buffer, x, 0) == :red
        assert :bold in get_modifiers(buffer, x, 0)
      end)
    end
  end

  describe "sizing" do
    test "renders with height and width" do
      element =
        rect style: [border: true, height: 5, width: 12] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────┐---
             │foo-------│---
             │----------│---
             │----------│---
             └──────────┘---
             ---------------\
             """
    end

    test "renders with height and width as percentage" do
      element =
        rect style: [border: true, height: "75%", width: "50%"] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 8})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────┐----------
             │foo-----│----------
             │--------│----------
             │--------│----------
             │--------│----------
             └────────┘----------
             --------------------
             --------------------\
             """

      element =
        rect style: [border: true, width: "70%"] do
          rect style: [border: true, width: "50%"] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 8})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────────┐------
             │┌────┐------│------
             ││foo-│------│------
             │└────┘------│------
             └────────────┘------
             --------------------
             --------------------
             --------------------\
             """
    end

    test "renders with height and width as fraction" do
      element =
        rect style: [border: true, width: "100%"], direction: :row do
          rect style: [border: true, width: "2fr"] do
            "foo"
          end

          rect style: [border: true, width: "3fr"] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 8})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌─────┐┌─────────┐│
             ││foo--││bar------││
             │└─────┘└─────────┘│
             └──────────────────┘
             --------------------
             --------------------
             --------------------\
             """

      element =
        rect style: [border: true, width: "100%"], direction: :column do
          rect style: [border: true, height: "2fr", width: "100%"] do
            "foo"
          end

          rect style: [border: true, height: "2fr", width: "100%"] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 12})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌────────────────┐│
             ││foo-------------││
             ││----------------││
             ││----------------││
             │└────────────────┘│
             │┌────────────────┐│
             ││bar-------------││
             ││----------------││
             ││----------------││
             │└────────────────┘│
             └──────────────────┘\
             """
    end

    test "if frational size is used, all children must be set" do
      assert_raise RuntimeError, ~r/Fractional width must be set for all children/, fn ->
        element =
          rect do
            rect style: [width: "2fr"] do
              "foo"
            end

            rect do
              "bar"
            end
          end

        Orange.Renderer.render(element, %{width: 20, height: 8})
      end

      assert_raise RuntimeError, ~r/Fractional height must be set for all children/, fn ->
        element =
          rect do
            rect style: [height: "2fr"] do
              "foo"
            end

            rect do
              "bar"
            end
          end

        Orange.Renderer.render(element, %{width: 20, height: 8})
      end
    end

    test "renders with height and width as calc expressions" do
      element =
        rect style: [border: true, height: "calc(75% + 1)", width: "calc(50% - 3)"] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 8})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────┐-------------
             │foo--│-------------
             │-----│-------------
             │-----│-------------
             │-----│-------------
             │-----│-------------
             └─────┘-------------
             --------------------\
             """

      element =
        rect style: [border: true, width: "70%"] do
          rect style: [border: true, width: "calc(25% + 4)"] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 8})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────────────┐------
             │┌─────┐-----│------
             ││foo--│-----│------
             │└─────┘-----│------
             └────────────┘------
             --------------------
             --------------------
             --------------------\
             """
    end
  end

  describe "border" do
    test "renders with borders" do
      element =
        rect style: [border: true, width: "100%"] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │foo----------│
             └─────────────┘
             ---------------
             ---------------\
             """
    end

    test "renders with no top border" do
      element =
        rect style: [
               border: true,
               border_top: false,
               width: "100%"
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             │foo----------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test "renders with no bottom border" do
      element =
        rect style: [
               border: true,
               border_bottom: false,
               width: "100%"
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │foo----------│
             ---------------
             ---------------
             ---------------\
             """
    end

    test "renders with no left border" do
      element =
        rect style: [
               border: true,
               border_left: false,
               width: "100%"
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ──────────────┐
             foo-----------│
             ──────────────┘
             ---------------
             ---------------\
             """
    end

    test "renders with no right border" do
      element =
        rect style: [
               border: true,
               border_right: false,
               width: "100%"
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────
             │foo-----------
             └──────────────
             ---------------
             ---------------\
             """
    end

    test "renders with border color" do
      element =
        rect style: [border: true, border_color: :red, height: 5, width: 12] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 15, height: 6})

      Enum.each(0..11, fn x ->
        assert get_color(buffer, x, 0) == :red
      end)
    end
  end

  describe "padding" do
    test "single value padding" do
      element =
        rect style: [padding: 1, border: true, width: "100%"] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │-------------│
             │-foo---------│
             │-------------│
             └─────────────┘
             ---------------
             ---------------\
             """
    end

    test "double values padding" do
      element =
        rect style: [padding: {1, 2}, border: true, width: "100%"] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │-------------│
             │--foo--------│
             │-------------│
             └─────────────┘
             ---------------
             ---------------\
             """
    end

    test "four-values padding" do
      element =
        rect style: [padding: {1, 2, 1, 3}, border: true, width: "100%"] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │-------------│
             │---foo-------│
             │-------------│
             └─────────────┘
             ---------------
             ---------------\
             """
    end
  end

  describe "line element" do
    test "renders a plain line" do
      element =
        line do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 10, height: 3})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             foo-------
             ----------
             ----------\
             """
    end

    test "renders with color" do
      element =
        line style: [color: :red] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 10, height: 3})

      Enum.each([{0, 0}, {1, 0}, {2, 0}], fn {x, y} ->
        assert get_color(buffer, x, y) == :red
      end)
    end

    test "renders with background color" do
      element =
        line style: [background_color: :red] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 10, height: 3})

      Enum.each([{0, 0}, {1, 0}, {2, 0}], fn {x, y} ->
        assert get_background_color(buffer, x, y) == :red
      end)
    end
  end

  describe "span element" do
    test "renders a plain span" do
      element =
        span do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 10, height: 3})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             foo-------
             ----------
             ----------\
             """
    end

    test "renders with color" do
      element =
        span style: [color: :red] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 10, height: 3})

      Enum.each([{0, 0}, {1, 0}, {2, 0}], fn {x, y} ->
        assert get_color(buffer, x, y) == :red
      end)
    end

    test "renders with background color" do
      element =
        span style: [background_color: :red] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 10, height: 3})

      Enum.each([{0, 0}, {1, 0}, {2, 0}], fn {x, y} ->
        assert get_background_color(buffer, x, y) == :red
      end)
    end

    test "renders with text modifiers" do
      element =
        span style: [text_modifiers: [:bold, :underline]] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 10, height: 3})

      Enum.each([{0, 0}, {1, 0}, {2, 0}], fn {x, y} ->
        assert :bold in get_modifiers(buffer, x, y)
        assert :underline in get_modifiers(buffer, x, y)
      end)
    end
  end

  describe "style inheritance" do
    test "inherits styles from ancestors" do
      element =
        line style: [color: :red, text_modifiers: [:bold]] do
          span do
            "foo"
          end
        end

      buffer = Orange.Renderer.render(element, %{width: 10, height: 3})

      Enum.each([{0, 0}, {1, 0}, {2, 0}], fn {x, y} ->
        assert get_color(buffer, x, y) == :red
        assert :bold in get_modifiers(buffer, x, y)
      end)
    end

    test "children styles have precedence over ancestor styles" do
      element =
        line style: [color: :red, text_modifiers: [:bold]] do
          span style: [color: :blue, text_modifiers: [:italic]] do
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
             │foob│---------
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
             │-fo-│---------
             │----│---------
             └────┘---------
             ---------------
             ---------------\
             """
    end

    test "multiple child, parent no padding" do
      element =
        rect style: [width: 6, border: true] do
          line do
            "foo"
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌────┐---------
             │foob│---------
             └────┘---------
             ---------------
             ---------------\
             """
    end

    test "multiple child, parent with padding" do
      element =
        rect style: [width: 8, padding: 1, border: true] do
          line do
            "foo"
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────┐-------
             │------│-------
             │-foob-│-------
             │------│-------
             └──────┘-------
             ---------------
             ---------------\
             """
    end

    test "vertical overflow" do
      element =
        rect style: [height: 3, border: true] do
          "foo"
          "bar"
          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌───┐----------
             │foo│----------
             └───┘----------
             ---------------
             ---------------
             ---------------
             ---------------\
             """
    end
  end

  describe "content scroll" do
    test "vertical scroll" do
      element =
        rect style: [width: "100%", height: 3], scroll_y: 1 do
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
             bar------------
             baz------------
             qux------------
             ---------------
             ---------------\
             """
    end

    test "vertical scroll with styled children" do
      element =
        rect style: [width: "100%", height: 5, padding: {0, 1}, border: true], scroll_y: 2 do
          rect style: [border: true] do
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
             │-│bar│-------│
             │-└───┘-------│
             │-baz---------│
             └─────────────┘\
             """
    end

    test "vertical over scroll" do
      element =
        rect style: [width: "100%", height: 3], scroll_y: 4 do
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

    test "horizontal scroll" do
      element =
        rect style: [width: 3, height: "100%"], scroll_x: 1 do
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
             oo-------------
             ar-------------
             az-------------
             ux-------------
             ---------------\
             """
    end

    test "horizontal scroll with styled children" do
      element =
        rect style: [width: 7, height: "100%", padding: {0, 1}, border: true], scroll_x: 2 do
          rect style: [border: true] do
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
             ┌─────┐--------
             │-──┐-│--------
             │-oo│-│--------
             │-ar│-│--------
             │-──┘-│--------
             │-z---│--------
             └─────┘--------\
             """
    end

    test "horizontal over scroll" do
      element =
        rect style: [width: 3, height: "100%"], scroll_x: 4 do
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

    test "scroll children has percentage size in scroll dimension" do
      element =
        rect style: [width: 2, height: "100%"], scroll_y: 1 do
          rect style: [height: "100%"] do
            "foo"
            "bar"
          end

          "baz"
          "qux"
        end

      assert_raise RuntimeError,
                   ~r/Vertical scroll boxes only support children with integer height, instead got 100%/,
                   fn ->
                     element
                     |> Orange.Renderer.render(%{width: 15, height: 5})
                     |> Orange.Renderer.Buffer.to_string()
                   end
    end

    test "scroll children has percentage size in other dimension" do
      element =
        rect style: [width: 2, height: "100%"], scroll_y: 1 do
          rect style: [width: "100%"] do
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
             ba-------------
             ba-------------
             qu-------------
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
             foo------------
             bar------------
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
            "qux"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             foo------------
             bar------------
             ┌─────────┐----
             │qux------│----
             │---------│──┐-
             │---------│--│-
             │---------│--│-
             └─────────┘--│-
             -└───────────┘-
             ---------------\
             """
    end

    test "root fixed element" do
      element =
        rect style: [border: true], position: {:fixed, 3, 3, 3, 3} do
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
             ---│foo----│---
             ---│bar----│---
             ---└───────┘---
             ---------------
             ---------------
             ---------------\
             """
    end

    test "overshadows layers behind" do
      element =
        rect style: [width: "100%", height: "100%"] do
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
          line do
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
          line do
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
          span style: [line_wrap: false] do
            "foo bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────┐--------
             │foo b│--------
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
