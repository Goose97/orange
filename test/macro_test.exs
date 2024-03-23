defmodule Orange.MacroTest do
  use ExUnit.Case
  import Orange.Macro

  describe "rect/2" do
    test "valid children" do
      element =
        rect do
          line do
            span do
              "foo"
            end
          end
        end

      assert element == %Orange.Rect{
               children: [%Orange.Line{children: [%Orange.Span{children: ["foo"]}]}]
             }
    end

    test "children are auto convert" do
      element1 =
        rect do
          span do
            "foo"
          end
        end

      element2 =
        rect do
          "foo"
        end

      assert element1 == %Orange.Rect{
               children: [%Orange.Line{children: [%Orange.Span{children: ["foo"]}]}]
             }

      assert element2 == %Orange.Rect{
               children: [%Orange.Line{children: [%Orange.Span{children: ["foo"]}]}]
             }
    end
  end

  describe "line/2" do
    test "valid children" do
      element =
        line do
          span do
            "foo"
          end
        end

      assert element == %Orange.Line{children: [%Orange.Span{children: ["foo"]}]}
    end

    test "children are auto convert" do
      element =
        line do
          "foo"
        end

      assert element == %Orange.Line{children: [%Orange.Span{children: ["foo"]}]}
    end
  end

  describe "span/2" do
    test "valid children" do
      element =
        span do
          "foo"
        end

      assert element == %Orange.Span{children: ["foo"]}
    end
  end

  describe "custom components" do
    test "no attributes" do
      element =
        rect do
          Orange.MacroTest.TestComponent
        end

      assert element == %Orange.Rect{
               children: [Orange.MacroTest.TestComponent],
               attributes: []
             }
    end

    test "with attributes" do
      element =
        rect do
          {Orange.MacroTest.TestComponent, style: [width: 20, height: 20], id: "foo"}
        end

      assert element == %Orange.Rect{
               children: [
                 {Orange.MacroTest.TestComponent, [style: [width: 20, height: 20], id: "foo"]}
               ],
               attributes: []
             }
    end
  end

  defmodule TestComponent do
    @behaviour Orange.Component

    @impl true
    def init(_attrs), do: nil

    @impl true
    def render(_state, _attrs, _update) do
      span do
        "Test Component"
      end
    end
  end
end
