defmodule Orange.Renderer.GridLayoutTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.Renderer.Buffer

  describe "display grid" do
    test "renders elements with grid display" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [{:fr, 1}, {:fr, 1}],
               grid_template_columns: [{:fr, 1}, {:fr, 1}]
             ] do
          rect style: [grid_row: {1, 2}, grid_column: {1, 2}, border: true] do
            "foo"
          end

          rect style: [grid_row: {2, 3}, grid_column: {2, 3}, border: true] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 8})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌───────┐---------│
             ││foo----│---------│
             │└───────┘---------│
             │---------┌───────┐│
             │---------│bar----││
             │---------└───────┘│
             └──────────────────┘\
             """
    end
  end

  describe "grid_template_rows and grid_template_columns" do
    test "accepts fixed integer" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [5, 7],
               grid_template_columns: [4, 7]
             ] do
          rect style: [grid_row: {1, 2}, grid_column: {1, 2}, border: true] do
            "foo"
          end

          rect style: [grid_row: {2, 3}, grid_column: {2, 3}, border: true] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 15})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌──┐--------------│
             ││foo--------------│
             ││--│--------------│
             ││--│--------------│
             │└──┘--------------│
             │----┌─────┐-------│
             │----│bar--│-------│
             │----│-----│-------│
             │----│-----│-------│
             │----│-----│-------│
             │----│-----│-------│
             │----└─────┘-------│
             │------------------│
             └──────────────────┘\
             """
    end

    test "accepts percentage" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: ["30%", "70%"],
               grid_template_columns: ["70%", "30%"]
             ] do
          rect style: [grid_row: {1, 2}, grid_column: {1, 2}, border: true] do
            "foo"
          end

          rect style: [grid_row: {2, 3}, grid_column: {2, 3}, border: true] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 22, height: 12})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌────────────────────┐
             │┌────────────┐------│
             ││foo---------│------│
             │└────────────┘------│
             │--------------┌────┐│
             │--------------│bar-││
             │--------------│----││
             │--------------│----││
             │--------------│----││
             │--------------│----││
             │--------------└────┘│
             └────────────────────┘\
             """
    end

    test "accepts fr" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [{:fr, 1}, {:fr, 1}],
               grid_template_columns: [{:fr, 1}, {:fr, 1}]
             ] do
          rect style: [grid_row: {1, 2}, grid_column: {1, 2}, border: true] do
            "foo"
          end

          rect style: [grid_row: {2, 3}, grid_column: {2, 3}, border: true] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 10})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌───────┐---------│
             ││foo----│---------│
             ││-------│---------│
             │└───────┘---------│
             │---------┌───────┐│
             │---------│bar----││
             │---------│-------││
             │---------└───────┘│
             └──────────────────┘\
             """
    end

    test "accepts auto" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [4, :auto, 4],
               grid_template_columns: [5, :auto, 5]
             ] do
          rect style: [grid_row: {1, 2}, grid_column: {1, 2}, border: true] do
            "foo"
          end

          rect style: [grid_row: {2, 3}, grid_column: {2, 3}, border: true] do
            "bar"
          end

          rect style: [grid_row: {3, 4}, grid_column: {3, 4}, border: true] do
            "baz"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 15})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌───┐-------------│
             ││foo│-------------│
             ││---│-------------│
             │└───┘-------------│
             │-----┌──────┐-----│
             │-----│bar---│-----│
             │-----│------│-----│
             │-----│------│-----│
             │-----└──────┘-----│
             │-------------┌───┐│
             │-------------│baz││
             │-------------│---││
             │-------------└───┘│
             └──────────────────┘\
             """
    end

    test "accepts repeat" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [{:repeat, 3, {:fr, 1}}],
               grid_template_columns: [{:repeat, 3, {:fr, 1}}]
             ] do
          rect style: [grid_row: {1, 2}, grid_column: {1, 2}, border: true] do
            "foo"
          end

          rect style: [grid_row: {2, 3}, grid_column: {2, 3}, border: true] do
            "bar"
          end

          rect style: [grid_row: {3, 4}, grid_column: {3, 4}, border: true] do
            "baz"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 17})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌────┐------------│
             ││foo-│------------│
             ││----│------------│
             ││----│------------│
             │└────┘------------│
             │------┌────┐------│
             │------│bar-│------│
             │------│----│------│
             │------│----│------│
             │------└────┘------│
             │------------┌────┐│
             │------------│baz-││
             │------------│----││
             │------------│----││
             │------------└────┘│
             └──────────────────┘\
             """
    end
  end

  describe "grid_row and grid_column" do
    test "accepts single fixed integer" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [4, :auto, 4],
               grid_template_columns: [5, :auto, 5]
             ] do
          rect style: [grid_row: 1, grid_column: 1, border: true] do
            "foo"
          end

          rect style: [grid_row: 3, grid_column: 3, border: true] do
            "bar"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 15})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌───┐-------------│
             ││foo│-------------│
             ││---│-------------│
             │└───┘-------------│
             │------------------│
             │------------------│
             │------------------│
             │------------------│
             │------------------│
             │-------------┌───┐│
             │-------------│bar││
             │-------------│---││
             │-------------└───┘│
             └──────────────────┘\
             """
    end

    test "accepts two fixed integers" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [4, :auto, 4],
               grid_template_columns: [5, :auto, 5]
             ] do
          rect style: [grid_row: {2, 3}, grid_column: {2, 3}, border: true] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 15})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │------------------│
             │------------------│
             │------------------│
             │------------------│
             │-----┌──────┐-----│
             │-----│foo---│-----│
             │-----│------│-----│
             │-----│------│-----│
             │-----└──────┘-----│
             │------------------│
             │------------------│
             │------------------│
             │------------------│
             └──────────────────┘\
             """
    end

    test "accepts single span" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [4, :auto, 4],
               grid_template_columns: [5, :auto, 5]
             ] do
          rect style: [grid_row: {:span, 2}, grid_column: {:span, 2}, border: true] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 15})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │┌───────────┐-----│
             ││foo--------│-----│
             ││-----------│-----│
             ││-----------│-----│
             ││-----------│-----│
             ││-----------│-----│
             ││-----------│-----│
             ││-----------│-----│
             │└───────────┘-----│
             │------------------│
             │------------------│
             │------------------│
             │------------------│
             └──────────────────┘\
             """
    end

    test "accepts single fixed integer and single span" do
      element =
        rect style: [
               border: true,
               height: "100%",
               width: "100%",
               display: :grid,
               grid_template_rows: [4, :auto, 4],
               grid_template_columns: [5, :auto, 5]
             ] do
          rect style: [grid_row: {2, {:span, 2}}, grid_column: {2, {:span, 2}}, border: true] do
            "foo"
          end
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 20, height: 15})
        |> elem(0)
        |> Buffer.to_string()

      assert screen == """
             ┌──────────────────┐
             │------------------│
             │------------------│
             │------------------│
             │------------------│
             │-----┌───────────┐│
             │-----│foo--------││
             │-----│-----------││
             │-----│-----------││
             │-----│-----------││
             │-----│-----------││
             │-----│-----------││
             │-----│-----------││
             │-----└───────────┘│
             └──────────────────┘\
             """
    end
  end
end
