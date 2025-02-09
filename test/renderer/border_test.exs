defmodule Orange.Renderer.BorderTest do
  use ExUnit.Case
  import Orange.Macro

  alias Orange.RendererTestHelper, as: Helper

  describe "border" do
    test "with borders" do
      element =
        rect style: [border: true, width: "100%"] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │foo----------│
             └─────────────┘
             ---------------
             ---------------\
             """
    end

    test "with no top border" do
      element =
        rect style: [
               border: true,
               border_top: false,
               width: "100%"
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             │foo----------│
             └─────────────┘
             ---------------
             ---------------
             ---------------\
             """
    end

    test "with no bottom border" do
      element =
        rect style: [
               border: true,
               border_bottom: false,
               width: "100%"
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌─────────────┐
             │foo----------│
             ---------------
             ---------------
             ---------------\
             """
    end

    test "with no left border" do
      element =
        rect style: [
               border: true,
               border_left: false,
               width: "100%"
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ──────────────┐
             foo-----------│
             ──────────────┘
             ---------------
             ---------------\
             """
    end

    test "with no right border" do
      element =
        rect style: [
               border: true,
               border_right: false,
               width: "100%"
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌──────────────
             │foo-----------
             └──────────────
             ---------------
             ---------------\
             """
    end

    test "with border color" do
      element =
        rect style: [border: true, border_color: :red, height: 5, width: 12] do
          "foo"
        end

      buffer = Orange.Renderer.render(element, %{width: 15, height: 6})

      Enum.each(0..11, fn x ->
        assert Helper.get_color(buffer, x, 0) == :red
      end)
    end

    test "with dashed border" do
      element =
        rect style: [
               border: true,
               border_style: :dashed,
               height: 5,
               width: 12
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ┌┄┄┄┄┄┄┄┄┄┄┐---
             ┆foo-------┆---
             ┆----------┆---
             ┆----------┆---
             └┄┄┄┄┄┄┄┄┄┄┘---\
             """
    end

    test "with round corners border" do
      element =
        rect style: [
               border: true,
               border_style: :round_corners,
               height: 5,
               width: 12
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ╭──────────╮---
             │foo-------│---
             │----------│---
             │----------│---
             ╰──────────╯---\
             """
    end

    test "with double border" do
      element =
        rect style: [
               border: true,
               border_style: :double,
               height: 5,
               width: 12
             ] do
          "foo"
        end

      screen =
        element
        |> Orange.Renderer.render(%{width: 15, height: 5})
        |> Orange.Renderer.Buffer.to_string()

      assert screen == """
             ╔══════════╗---
             ║foo-------║---
             ║----------║---
             ║----------║---
             ╚══════════╝---\
             """
    end
  end
end
