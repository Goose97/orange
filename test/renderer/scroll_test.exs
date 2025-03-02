require Logger

defmodule Orange.Renderer.ScrollTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "vertical scroll" do
    test "no overflow - no scroll offset" do
      element =
        rect style: [width: "100%", height: 4, flex_direction: :column], scroll_y: 0 do
          "line0"
          "line1"
          "line2"
          "line3"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 4})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             line0---------▐
             line1---------▐
             line2---------▐
             line3---------▐\
             """
    end

    test "no overflow - with scroll offset" do
      element =
        rect style: [width: "100%", height: 6, flex_direction: :column], scroll_y: 1 do
          "line0"
          "line1"
          "line2"
          "line3"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             line1---------▐
             line2---------▐
             line3---------▐
             --------------▐
             --------------▐
             --------------▐\
             """
    end

    test "overflow - no scroll offset" do
      element =
        rect style: [width: "100%", height: 3, flex_direction: :column], scroll_y: 0 do
          "line1"
          "line2"
          "line3"
          "line4"
          "line5"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 3})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             line1---------▐
             line2---------▐
             line3---------│\
             """
    end

    test "overflow - with scroll offset" do
      element =
        rect style: [width: "100%", height: 3, flex_direction: :column], scroll_y: 2 do
          "line1"
          "line2"
          "line3"
          "line4"
          "line5"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 3})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             line3---------│
             line4---------▐
             line5---------▐\
             """
    end

    test "when scroll_y is specified, it implies border right" do
      # It renders the scroll bar on top of the border
      element =
        rect style: [width: "100%", height: 3, flex_direction: :column, border_right: false],
             scroll_y: 2 do
          "line1"
          "line2"
          "line3"
          "line4"
          "line5"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 3})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             line3---------│
             line4---------▐
             line5---------▐\
             """
    end
  end

  describe "horizontal scroll" do
    test "no overflow - no scroll offset" do
      element =
        rect style: [width: 5, flex_direction: :column], scroll_x: 0 do
          "line0"
          "line1"
          "line2"
          "line3"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             line0----------
             line1----------
             line2----------
             line3----------
             🭹🭹🭹🭹🭹----------\
             """
    end

    test "no overflow - with scroll offset" do
      element =
        rect style: [width: 5, flex_direction: :column], scroll_x: 1 do
          "line0"
          "line1"
          "line2"
          "line3"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ine0-----------
             ine1-----------
             ine2-----------
             ine3-----------
             🭹🭹🭹🭹🭹----------
             ---------------\
             """
    end

    test "overflow - no scroll offset" do
      element =
        rect style: [width: 3, flex_direction: :column], scroll_x: 0 do
          "line1"
          "line2"
          "line3"
          "line4"
          "line5"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             lin------------
             lin------------
             lin------------
             lin------------
             lin------------
             🭹🭹─------------
             ---------------\
             """
    end

    test "overflow - with scroll offset" do
      element =
        rect style: [width: 3, flex_direction: :column], scroll_x: 2 do
          "line1"
          "line2"
          "line3"
          "line4"
          "line5"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ne1------------
             ne2------------
             ne3------------
             ne4------------
             ne5------------
             ─🭹🭹------------
             ---------------\
             """
    end

    test "when scroll_x is specified, it implies border bottom" do
      # It renders the scroll bar on top of the border
      element =
        rect style: [width: 4, flex_direction: :column, border_bottom: false],
             scroll_x: 1 do
          "line1"
          "line2"
          "line3"
          "line4"
          "line5"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 7})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ine1-----------
             ine2-----------
             ine3-----------
             ine4-----------
             ine5-----------
             ─🭹🭹🭹-----------
             ---------------\
             """
    end
  end

  test "scroll bar color matches the border color" do
    element =
      rect style: [width: 4, flex_direction: :column, border_color: :red], scroll_x: 0 do
        "line0"
        "line1"
        "line2"
        "line3"
      end

    {buffer, _} =
      element
      |> Orange.Renderer.render(%{width: 15, height: 5})

    Enum.each(0..3, fn x ->
      assert Buffer.get_color(buffer, x, 4) == :red
    end)
  end

  describe "scroll_bar style attribute" do
    test "vertical scroll bar is visible by default" do
      element =
        rect style: [width: "100%", height: 3, flex_direction: :column], scroll_y: 0 do
          "line1"
          "line2"
          "line3"
          "line4"
          "line5"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 3})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             line1---------▐
             line2---------▐
             line3---------│\
             """
    end

    test "vertical scroll bar can be hidden" do
      element =
        rect style: [width: "100%", height: 3, flex_direction: :column, scroll_bar: :hidden],
             scroll_y: 0 do
          "line1"
          "line2"
          "line3"
          "line4"
          "line5"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 3})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             line1----------
             line2----------
             line3----------\
             """
    end

    test "horizontal scroll bar is visible by default" do
      element =
        rect style: [width: 3, flex_direction: :column], scroll_x: 0 do
          "line1"
          "line2"
          "line3"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             lin------------
             lin------------
             lin------------
             🭹🭹─------------
             ---------------\
             """
    end

    test "horizontal scroll bar can be hidden" do
      element =
        rect style: [width: 3, flex_direction: :column, scroll_bar: :hidden], scroll_x: 0 do
          "line1"
          "line2"
          "line3"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             lin------------
             lin------------
             lin------------
             ---------------
             ---------------\
             """
    end
  end
end
