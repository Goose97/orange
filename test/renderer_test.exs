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
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             foo------------
             ---------------
             ---------------
             ---------------
             ---------------\
             """
    end

    test "renders a rect with empty string" do
      element =
        rect do
          "   "
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
                ------------
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
        |> elem(0)
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
        |> elem(0)
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
        |> elem(0)
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
        |> elem(0)
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

    test "raises error when given invalid children" do
      element =
        rect do
          1
        end

      assert_raise RuntimeError,
                   "Elixir.Orange.Renderer.InputTree.to_input_tree: invalid element children. Expected a string or another element, got 1",
                   fn ->
                     Orange.Renderer.render(element, %{width: 15, height: 5})
                   end
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

      {buffer, _} = Orange.Renderer.render(element, %{width: 10, height: 3})

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

      {buffer, _} = Orange.Renderer.render(element, %{width: 10, height: 3})

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
        |> elem(0)
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
        |> elem(0)
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
        |> elem(0)
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

  describe "background text" do
    test "takes a string" do
      element =
        rect style: [width: 10, height: 4, border: true], background_text: "|" do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> elem(0)
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

      {buffer, _} =
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
