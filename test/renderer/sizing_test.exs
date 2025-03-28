defmodule Orange.Renderer.SizingTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "sizing" do
    test "renders with height and width" do
      element =
        rect style: [border: true, height: 5, width: 12] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 6})
        |> elem(0)
        |> Buffer.to_string()

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
        |> elem(0)
        |> Buffer.to_string()

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
        |> elem(0)
        |> Buffer.to_string()

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

    test "renders with min_width" do
      element =
        rect style: [border: true, min_width: 10] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 5})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌────────┐----------
             │foo-----│----------
             └────────┘----------
             --------------------
             --------------------\
             """
    end

    test "renders with max_width" do
      element =
        rect style: [border: true, max_width: 3] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 5})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌─┐-----------------
             │foo----------------
             └─┘-----------------
             --------------------
             --------------------\
             """
    end

    test "renders with min_height" do
      element =
        rect style: [border: true, min_height: 5] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 8})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌───┐---------------
             │foo│---------------
             │---│---------------
             │---│---------------
             └───┘---------------
             --------------------
             --------------------
             --------------------\
             """
    end

    test "renders with max_height" do
      element =
        rect style: [border: true, max_height: 2] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 5})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌───┐---------------
             └foo┘---------------
             --------------------
             --------------------
             --------------------\
             """
    end
  end

  describe "padding" do
    test "single value padding" do
      element =
        rect style: [padding: 1, border: true, width: "100%"] do
          rect style: [padding: 2, border: true, width: "100%"] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 12})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │-------------│
             │-┌─────────┐-│
             │-│---------│-│
             │-│---------│-│
             │-│--foo----│-│
             │-│---------│-│
             │-│---------│-│
             │-└─────────┘-│
             │-------------│
             └─────────────┘
             ---------------\
             """
    end

    test "double values padding" do
      element =
        rect style: [padding: {1, 2}, border: true, width: "100%"] do
          rect style: [padding: {1, 1}, border: true, width: "100%"] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │-------------│
             │--┌───────┐--│
             │--│-------│--│
             │--│-foo---│--│
             │--│-------│--│
             │--└───────┘--│
             │-------------│
             └─────────────┘
             ---------------\
             """
    end

    test "four-values padding" do
      element =
        rect style: [padding: {1, 2, 1, 3}, border: true, width: "100%"] do
          rect style: [padding: {2, 1, 3, 1}, border: true, width: "100%"] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 12})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │-------------│
             │---┌──────┐--│
             │---│------│--│
             │---│------│--│
             │---│-foo--│--│
             │---│------│--│
             │---│------│--│
             │---│------│--│
             │---└──────┘--│
             │-------------│
             └─────────────┘\
             """
    end
  end

  describe "margin" do
    test "single value margin" do
      element =
        rect style: [border: true, width: "100%"] do
          rect style: [border: true, width: "100%"] do
            "foo"
          end

          rect style: [margin: 2, border: true, width: "100%"] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 12})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌─────┐-----------│
             ││foo--│-----------│
             ││-----│--┌─────┐--│
             ││-----│--│bar--│--│
             ││-----│--└─────┘--│
             ││-----│-----------│
             │└─────┘-----------│
             └──────────────────┘
             --------------------
             --------------------
             --------------------\
             """
    end

    test "double values margin" do
      element =
        rect style: [border: true, width: "100%"] do
          rect style: [border: true, width: "100%"] do
            "foo"
          end

          rect style: [margin: {1, 2}, border: true, width: "100%"] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 10})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │┌───┐--------│
             ││foo│--┌───┐-│
             ││---│--│bar│-│
             ││---│--└───┘-│
             │└───┘--------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test "four-values margin" do
      element =
        rect style: [border: true, width: "100%"] do
          rect style: [border: true, width: "100%"] do
            "foo"
          end

          rect style: [margin: {1, 2, 3, 4}, border: true, width: "100%"] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 12})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌────┐------------│
             ││foo-│----┌────┐--│
             ││----│----│bar-│--│
             ││----│----└────┘--│
             ││----│------------│
             ││----│------------│
             │└────┘------------│
             └──────────────────┘
             --------------------
             --------------------
             --------------------\
             """
    end
  end
end
