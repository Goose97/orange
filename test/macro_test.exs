defmodule Orange.MacroTest do
  use ExUnit.Case
  import Orange.Macro

  describe "rect/2" do
    test "valid children" do
      element =
        rect do
          rect do
            rect do
              "foo"
            end
          end
        end

      assert element == %Orange.Rect{
               children: [%Orange.Rect{children: [%Orange.Rect{children: ["foo"]}]}]
             }
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
      rect do
        "Test Component"
      end
    end
  end
end
