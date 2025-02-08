defmodule Orange.Renderer.ColorTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.RendererTestHelper, as: Helper

  describe "color" do
    test "renders cells with color" do
      element =
        rect style: [border: true, width: 10, color: :red] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Orange.Renderer.Buffer.to_string(buffer)

      assert screen == """
             ┌────────┐-----
             │foo-----│-----
             └────────┘-----
             ---------------
             ---------------
             ---------------\
             """

      Enum.each(1..3, fn x ->
        assert Helper.get_color(buffer, x, 1) == :red
      end)
    end
  end

  describe "background color" do
    test "renders cells with background color" do
      element =
        rect style: [border: true, width: 10, background_color: :red] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 15, height: 6})
      screen = Orange.Renderer.Buffer.to_string(buffer)

      assert screen == """
             ┌────────┐-----
             │foo     │-----
             └────────┘-----
             ---------------
             ---------------
             ---------------\
             """

      Enum.each(0..2, fn y ->
        Enum.each(0..9, fn x ->
          assert Helper.get_background_color(buffer, x, y) == :red
        end)
      end)
    end
  end
end
