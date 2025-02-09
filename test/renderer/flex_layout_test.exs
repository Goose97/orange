defmodule Orange.Renderer.FlexLayoutTest do
  use ExUnit.Case
  import Orange.Macro

  describe "flex_direction" do
    test "renders elements in the horizontal direction if flex_direction is :row" do
      element =
        rect style: [border: true, height: 5, width: 12, flex_direction: :row] do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────┐---
             │foobar----│---
             │----------│---
             │----------│---
             └──────────┘---
             ---------------\
             """
    end

    test "renders elements in the vertical direction if flex_direction is :column" do
      element =
        rect style: [border: true, height: 5, width: 12, flex_direction: :column] do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────┐---
             │foo-------│---
             │bar-------│---
             │----------│---
             └──────────┘---
             ---------------\
             """
    end
  end

  describe "flex_grow" do
    test "renders elements with corresponding flex_grow" do
      element =
        rect style: [border: true, height: 5, width: "100%", flex_direction: :row] do
          "foo"

          rect style: [flex_grow: 1] do
            "bar"
          end

          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │foobar---------baz│
             │------------------│
             │------------------│
             └──────────────────┘
             --------------------\
             """
    end
  end

  describe "flex_shrink" do
    test "renders elements with corresponding flex_shrink" do
      element =
        rect style: [border: true, height: "100%", width: "100%", flex_direction: :row] do
          rect style: [width: 7, flex_shrink: 0] do
            "foo"
          end

          rect style: [width: 7, flex_shrink: 1] do
            "bar"
          end

          rect style: [width: 7, flex_shrink: 0] do
            "baz"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │foo----bar-baz----│
             │------------------│
             │------------------│
             │------------------│
             └──────────────────┘\
             """
    end
  end

  describe "justify_content" do
    test "renders elements with corresponding justify_content" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               flex_direction: :row,
               justify_content: :center
             ] do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │------foobar------│
             │------------------│
             │------------------│
             │------------------│
             └──────────────────┘\
             """
    end
  end

  describe "align_items" do
    test "renders elements with corresponding align_items" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               flex_direction: :row,
               align_items: :center
             ] do
          "foo"
          "bar"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 7})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │------------------│
             │------------------│
             │foobar------------│
             │------------------│
             │------------------│
             └──────────────────┘\
             """
    end
  end

  describe "gap" do
    test "renders elements with gap, acts as shorthand for row_gap and column_gap" do
      element =
        rect style: [border: true, height: 10, width: 12, flex_direction: :column, gap: 2] do
          "foo"
          "bar"
          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────┐---
             │foo-------│---
             │----------│---
             │----------│---
             │bar-------│---
             │----------│---
             │----------│---
             │baz-------│---
             │----------│---
             └──────────┘---\
             """

      element =
        rect style: [border: true, height: 5, width: 20, flex_direction: :row, gap: 3] do
          "foo"
          "bar"
          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐-----
             │foo---bar---baz---│-----
             │------------------│-----
             │------------------│-----
             └──────────────────┘-----
             -------------------------\
             """
    end

    test "renders elements with row_gap" do
      element =
        rect style: [border: true, height: 10, width: 12, flex_direction: :column, row_gap: 2] do
          "foo"
          "bar"
          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────┐---
             │foo-------│---
             │----------│---
             │----------│---
             │bar-------│---
             │----------│---
             │----------│---
             │baz-------│---
             │----------│---
             └──────────┘---\
             """
    end

    test "renders elements with column_gap" do
      element =
        rect style: [border: true, height: 5, width: 20, flex_direction: :row, column_gap: 3] do
          "foo"
          "bar"
          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐-----
             │foo---bar---baz---│-----
             │------------------│-----
             │------------------│-----
             └──────────────────┘-----
             -------------------------\
             """
    end

    test "row_gap has higher priority than gap" do
      element =
        rect style: [
               border: true,
               height: 10,
               width: 12,
               flex_direction: :column,
               gap: 4,
               row_gap: 2
             ] do
          "foo"
          "bar"
          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────┐---
             │foo-------│---
             │----------│---
             │----------│---
             │bar-------│---
             │----------│---
             │----------│---
             │baz-------│---
             │----------│---
             └──────────┘---\
             """
    end

    test "column_gap has higher priority than gap" do
      element =
        rect style: [
               border: true,
               height: 5,
               width: 20,
               flex_direction: :row,
               gap: 6,
               column_gap: 3
             ] do
          "foo"
          "bar"
          "baz"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 6})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────────┐-----
             │foo---bar---baz---│-----
             │------------------│-----
             │------------------│-----
             └──────────────────┘-----
             -------------------------\
             """
    end
  end
end
