defmodule Orange.Runtime.ChildrenDiffTest do
  use ExUnit.Case

  alias Orange.{Rect, CustomComponent}
  alias Orange.Runtime.ChildrenDiff

  describe "run/2" do
    test "stateless children" do
      list1 = [
        "Text: 0",
        "Text: 1",
        "Text: 2"
      ]

      list2 = [
        "Text: 1",
        "Text: 2",
        "Text: 3"
      ]

      assert ChildrenDiff.run(list2, list1) ==
               [
                 {:new, "Text: 1"},
                 {:new, "Text: 2"},
                 {:new, "Text: 3"}
               ]

      list1 = [
        "Text: 0",
        "Text: 1",
        "Text: 2"
      ]

      list2 = [
        "Text: 1",
        %Rect{children: ["Text: 2"]},
        "Text: 3"
      ]

      assert ChildrenDiff.run(list2, list1) ==
               [
                 {:new, "Text: 1"},
                 {:new, %Orange.Rect{children: ["Text: 2"], attributes: []}},
                 {:new, "Text: 3"},
                 {:remove, "Text: 1"}
               ]
    end

    test "stateful children" do
      list1 = [
        "Text: 0",
        %Rect{children: ["Text: 1"]}
      ]

      list2 = [
        "Text: 1",
        %Rect{children: ["Text: 2"]}
      ]

      assert ChildrenDiff.run(list2, list1) ==
               [
                 {:new, "Text: 1"},
                 {:keep, %Rect{children: ["Text: 2"], attributes: []},
                  %Rect{children: ["Text: 1"], attributes: []}}
               ]
    end

    test "same custom components" do
      list1 = [
        %CustomComponent{children: ["Text: 0"]},
        %Rect{children: ["Text: 1"]}
      ]

      list2 = [
        %CustomComponent{children: ["Text: 1"]},
        "Text: 1",
        %Rect{children: ["Text: 2"]}
      ]

      assert ChildrenDiff.run(list2, list1) ==
               [
                 {:keep,
                  %Orange.CustomComponent{
                    children: ["Text: 1"],
                    attributes: []
                  },
                  %Orange.CustomComponent{
                    children: ["Text: 0"],
                    attributes: []
                  }},
                 {:new, "Text: 1"},
                 {:keep, %Orange.Rect{children: ["Text: 2"], attributes: []},
                  %Orange.Rect{children: ["Text: 1"], attributes: []}}
               ]
    end

    test "different custom components" do
      list1 = [
        %CustomComponent{children: ["Text: 0"], module: :foo},
        %Rect{children: ["Text: 1"]}
      ]

      list2 = [
        %CustomComponent{children: ["Text: 1"], module: :bar},
        "Text: 1",
        %Rect{children: ["Text: 2"]}
      ]

      assert ChildrenDiff.run(list2, list1) ==
               [
                 {:new,
                  %Orange.CustomComponent{
                    module: :bar,
                    children: ["Text: 1"],
                    attributes: []
                  }},
                 {:new, "Text: 1"},
                 {:keep, %Orange.Rect{children: ["Text: 2"], attributes: []},
                  %Orange.Rect{children: ["Text: 1"], attributes: []}},
                 {:remove,
                  %Orange.CustomComponent{
                    module: :foo,
                    children: ["Text: 0"],
                    ref: nil,
                    attributes: []
                  }}
               ]
    end

    test "remove components" do
      list1 = [
        %CustomComponent{children: ["Text: 0"], module: :foo},
        %CustomComponent{children: ["Text: 1"], module: :foo},
        %Rect{children: ["Text: 1"]}
      ]

      list2 = [
        %CustomComponent{children: ["Text: 1"], module: :foo},
        %Rect{children: ["Text: 1"]}
      ]

      assert ChildrenDiff.run(list2, list1) == [
               {:keep,
                %Orange.CustomComponent{
                  module: :foo,
                  children: ["Text: 1"],
                  ref: nil,
                  attributes: []
                },
                %Orange.CustomComponent{
                  module: :foo,
                  children: ["Text: 0"],
                  ref: nil,
                  attributes: []
                }},
               {:keep, %Orange.Rect{children: ["Text: 1"], attributes: []},
                %Orange.Rect{children: ["Text: 1"], attributes: []}},
               {:remove,
                %Orange.CustomComponent{
                  module: :foo,
                  children: ["Text: 1"],
                  ref: nil,
                  attributes: []
                }}
             ]
    end

    test "prioritize from the left" do
      list1 = [
        %CustomComponent{children: ["Text: 0"], module: :foo},
        %CustomComponent{children: ["Text: 1"], module: :foo}
      ]

      list2 = [
        %CustomComponent{children: ["Text: 0"], module: :foo}
      ]

      assert ChildrenDiff.run(list2, list1) ==
               [
                 {:keep,
                  %Orange.CustomComponent{
                    module: :foo,
                    children: ["Text: 0"],
                    ref: nil,
                    attributes: []
                  },
                  %Orange.CustomComponent{
                    module: :foo,
                    children: ["Text: 0"],
                    ref: nil,
                    attributes: []
                  }},
                 {:remove,
                  %Orange.CustomComponent{
                    module: :foo,
                    children: ["Text: 1"],
                    attributes: []
                  }}
               ]
    end
  end
end
