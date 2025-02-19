defmodule Orange.Renderer.FixedPositionTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

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
        |> elem(0)
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
        |> elem(0)
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
        |> elem(0)
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
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             111------------
             2┌───────────┐-
             3│foo--------│-
             4└───────────┘-
             555------------\
             """
    end

    test "when left is speicified, right is NOT specified" do
      element =
        rect style: [border: true], position: {:fixed, 3, nil, 3, 3} do
          rect style: [flex_direction: :column] do
            "foo"
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ---------------
             ---------------
             ---------------
             ---┌───┐-------
             ---│foo│-------
             ---│bar│-------
             ---└───┘-------
             ---------------
             ---------------
             ---------------\
             """
    end

    test "when left is NOT speicified, right is specified" do
      element =
        rect style: [border: true], position: {:fixed, 3, 1, 3, nil} do
          rect style: [flex_direction: :column] do
            "foo"
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ---------------
             ---------------
             ---------------
             ---------┌───┐-
             ---------│foo│-
             ---------│bar│-
             ---------└───┘-
             ---------------
             ---------------
             ---------------\
             """
    end

    test "when top is speicified, bottom is NOT specified" do
      element =
        rect style: [border: true], position: {:fixed, 2, 1, nil, 4} do
          rect style: [flex_direction: :column] do
            "foo"
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ---------------
             ---------------
             ----┌────────┐-
             ----│foo-----│-
             ----│bar-----│-
             ----└────────┘-
             ---------------
             ---------------
             ---------------
             ---------------\
             """
    end

    test "when top is NOT speicified, bottom is specified" do
      element =
        rect style: [border: true], position: {:fixed, nil, 1, 1, 4} do
          rect style: [flex_direction: :column] do
            "foo"
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ---------------
             ---------------
             ---------------
             ---------------
             ---------------
             ----┌────────┐-
             ----│foo-----│-
             ----│bar-----│-
             ----└────────┘-
             ---------------\
             """
    end

    test "inherits parent style" do
      element =
        rect style: [width: "100%", height: 3, color: :red] do
          rect do
            "foo"
            "bar"
          end

          rect position: {:fixed, 4, 1, 1, 1}, style: [border: true] do
            "baz"
          end
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})

      Enum.each(2..4, fn x ->
        assert Buffer.get_color(buffer, x, 5) == :red
      end)
    end

    @tag capture_log: true
    test "fixed position must specify at least left or right" do
      %RuntimeError{message: message} =
        Orange.Test.render_catch_error(
          rect do
            rect position: {:fixed, 0, nil, 0, nil} do
              "test"
            end
          end,
          terminal_size: {20, 15}
        )

      assert message =~ "Fixed position element must specify either left or right"
    end

    @tag capture_log: true
    test "fixed position must specify at least top or bottom" do
      %RuntimeError{message: message} =
        Orange.Test.render_catch_error(
          rect do
            rect position: {:fixed, nil, 0, nil, 0} do
              "test"
            end
          end,
          terminal_size: {20, 15}
        )

      assert message =~ "Fixed position element must specify either top or bottom"
    end
  end
end
