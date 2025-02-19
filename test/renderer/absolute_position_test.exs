defmodule Orange.Renderer.AbsolutePositionTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "absolute position" do
    test "absolute element" do
      element =
        rect style: [width: "100%", height: "100%"] do
          rect do
            "foo"
            "bar"
          end

          rect position: {:absolute, 4, 1, 1, 1}, style: [border: true] do
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

    test "absolute element in nested children" do
      element =
        rect style: [width: "100%", height: "100%", padding: 1] do
          rect style: [width: 10, height: 10, border: true] do
            "foo"
            "bar"

            rect position: {:absolute, 4, 1, 2, 1}, style: [border: true] do
              "baz"
            end
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 13})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             -------------------------
             -┌────────┐--------------
             -│foobar--│--------------
             -│--------│--------------
             -│--------│--------------
             -│┌──────┐│--------------
             -││baz---││--------------
             -││------││--------------
             -│└──────┘│--------------
             -│--------│--------------
             -└────────┘--------------
             -------------------------
             -------------------------\
             """
    end

    test "when left is specified, right is NOT specified" do
      element =
        rect style: [width: "100%", height: "100%", padding: 1] do
          rect style: [width: 10, height: 10, border: true] do
            "foo"
            "bar"

            rect position: {:absolute, 4, nil, 2, 1}, style: [border: true] do
              "baz"
            end
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 13})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             -------------------------
             -┌────────┐--------------
             -│foobar--│--------------
             -│--------│--------------
             -│--------│--------------
             -│┌───┐---│--------------
             -││baz│---│--------------
             -││---│---│--------------
             -│└───┘---│--------------
             -│--------│--------------
             -└────────┘--------------
             -------------------------
             -------------------------\
             """
    end

    test "when left is NOT specified, right is specified" do
      element =
        rect style: [width: "100%", height: "100%", padding: 1] do
          rect style: [width: 10, height: 10, border: true] do
            "foo"
            "bar"

            rect position: {:absolute, 4, 1, 2, nil}, style: [border: true] do
              "baz"
            end
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 13})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             -------------------------
             -┌────────┐--------------
             -│foobar--│--------------
             -│--------│--------------
             -│--------│--------------
             -│---┌───┐│--------------
             -│---│baz││--------------
             -│---│---││--------------
             -│---└───┘│--------------
             -│--------│--------------
             -└────────┘--------------
             -------------------------
             -------------------------\
             """
    end

    test "when top is specified, bottom is NOT specified" do
      element =
        rect style: [width: "100%", height: "100%", padding: 1] do
          rect style: [width: 10, height: 10, border: true] do
            "foo"
            "bar"

            rect position: {:absolute, 4, 1, nil, 1}, style: [border: true] do
              "baz"
            end
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 13})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             -------------------------
             -┌────────┐--------------
             -│foobar--│--------------
             -│--------│--------------
             -│--------│--------------
             -│┌──────┐│--------------
             -││baz---││--------------
             -│└──────┘│--------------
             -│--------│--------------
             -│--------│--------------
             -└────────┘--------------
             -------------------------
             -------------------------\
             """
    end

    test "when top is NOT specified, bottom is specified" do
      element =
        rect style: [width: "100%", height: "100%", padding: 1] do
          rect style: [width: 10, height: 10, border: true] do
            "foo"
            "bar"

            rect position: {:absolute, nil, 1, 1, 1}, style: [border: true] do
              "baz"
            end
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 13})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             -------------------------
             -┌────────┐--------------
             -│foobar--│--------------
             -│--------│--------------
             -│--------│--------------
             -│--------│--------------
             -│--------│--------------
             -│┌──────┐│--------------
             -││baz---││--------------
             -│└──────┘│--------------
             -└────────┘--------------
             -------------------------
             -------------------------\
             """
    end

    test "when width from left and right is too small" do
      element =
        rect style: [width: "100%", height: "100%", padding: 1] do
          rect style: [width: 10, height: 10, border: true] do
            "foo"
            "bar"

            rect position: {:absolute, 4, 6, 1, 5}, style: [border: true] do
              "baz"
            end
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 13})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             -------------------------
             -┌────────┐--------------
             -│foobar--│--------------
             -│--------│--------------
             -│--------│--------------
             -│----┌┐--│--------------
             -│----│baz│--------------
             -│----││--│--------------
             -│----││--│--------------
             -│----└┘--│--------------
             -└────────┘--------------
             -------------------------
             -------------------------\
             """
    end

    test "when height from top and bottom is too small" do
      element =
        rect style: [width: "100%", height: "100%", padding: 1] do
          rect style: [width: 10, height: 10, border: true] do
            "foo"
            "bar"

            rect position: {:absolute, 6, 1, 7, 1}, style: [border: true] do
              "baz"
            end
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 25, height: 13})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             -------------------------
             -┌────────┐--------------
             -│foobar--│--------------
             -│--------│--------------
             -│--------│--------------
             -│--------│--------------
             -│--------│--------------
             -│┌──────┐│--------------
             -│└baz───┘│--------------
             -│--------│--------------
             -└────────┘--------------
             -------------------------
             -------------------------\
             """
    end

    test "inherits parent style" do
      element =
        rect style: [width: "100%", height: "100%", color: :red] do
          rect do
            "foo"
            "bar"
          end

          rect position: {:absolute, 4, 1, 1, 1}, style: [border: true] do
            "baz"
          end
        end

      {buffer, _} =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})

      Enum.each(2..4, fn x ->
        assert Buffer.get_color(buffer, x, 5) == :red
      end)

      """
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

    @tag capture_log: true
    test "absolute position must specify at least left or right" do
      %RuntimeError{message: message} =
        Orange.Test.render_catch_error(
          rect do
            rect position: {:absolute, 0, nil, 0, nil} do
              "test"
            end
          end,
          terminal_size: {20, 15}
        )

      assert message =~ "Absolute position element must specify either left or right"
    end

    @tag capture_log: true
    test "absolute position must specify at least top or bottom" do
      %RuntimeError{message: message} =
        Orange.Test.render_catch_error(
          rect do
            rect position: {:absolute, nil, 0, nil, 0} do
              "test"
            end
          end,
          terminal_size: {20, 15}
        )

      assert message =~ "Absolute position element must specify either top or bottom"
    end

    @tag capture_log: true
    test "root element CAN NOT have absolute position" do
      %RuntimeError{message: message} =
        Orange.Test.render_catch_error(
          rect position: {:absolute, nil, 0, nil, 0} do
            "test"
          end,
          terminal_size: {20, 15}
        )

      assert message =~ "Absolute position can't be used on root element"
    end
  end
end
