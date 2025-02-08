defmodule Orange.RendererTestHelper do
  def get_color(buffer, x, y) do
    cell = Orange.Renderer.Buffer.get_cell(buffer, {x, y})
    cell.foreground
  end

  def get_background_color(buffer, x, y) do
    cell = Orange.Renderer.Buffer.get_cell(buffer, {x, y})
    cell.background
  end

  def get_modifiers(buffer, x, y) do
    cell = Orange.Renderer.Buffer.get_cell(buffer, {x, y})
    cell.modifiers
  end
end
