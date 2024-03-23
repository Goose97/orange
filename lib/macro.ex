defmodule Orange.Macro do
  @moduledoc """
  Macros for creating Orange primitive components

  Currently, Orange supports three primitive components:
    * `rect` for creating a rectangle
    * `line` for creating a line
    * `span` for creating a span

  ## Examples

  Macro provides an ergonomic way to create Orange components. For example, the following code:

      rect style: [width: 12, border: true], direction: :row do
        span style: [color: :red] do
          "Hello"
        end

        span do
          "World"
        end
      end

  will produce the following struct:

      %Orange.Rect{
        children: [
          %Orange.Line{
            children: [
              %Orange.Span{children: ["Hello"], attributes: [style: [color: :red]]}
            ],
            attributes: []
          },
          %Orange.Line{
            children: [%Orange.Span{children: ["World"], attributes: []}],
            attributes: []
          }
        ],
        attributes: [style: [width: 12, border: true], direction: :row]
      }

  ## Components children

  Orange components can have children, provided by the do block. The syntax took inspiration from HTML:

      rect do
        span do
          "Hello"
        end

        span do
          "World"
        end
      end

  The children can also be a list of components. This is useful when you want to render a collection of components. For example:

      rect do
        [
          span do
            "Hello"
          end,

          span do
            "World"
          end
        ]
      end

  Normal Elixir expression works inside the children block. For example, here's how to conditionally render components:

      rect do
        if :rand.uniform() > 0.5 do
          "Hello"
        else
          "World"
        end
      end

  ## Styling

  ### Sizing

    * `:width` - the width of the component

    * `:height` - the height of the component

  The values for `width` and `height` can be:

    * An integer - the number of cells in the terminal. For example: `style: [width: 10]`

    * A percentage string - the size is equal to the given percentage of the parent size. For example: `style: [width: "50%"]`

    * An calc expression - the size is calculated based on the given expression. For example: `style: [width: "calc(100% - 10)"]`

    * A fraction string - the size is calculated based on the given fraction of the parent size. All sibling components MUST also have a fraction size. The size will be calculated based on the component fraction divided by the sum of all sibling fractions. For example:

      ```
      rect style: [width: 12] do
        rect style: [width: "1fr"] do
        end

        rect style: [width: "2fr"] do
        end
      end
      ```

      In this example, the first rect will have a width of 1/3 of the parent rect, and the second rect will have a width of 2/3 of the parent rect.

  ### Padding

  Padding for the render box's inner content. The values for `padding` can be:

    * One integer - padding for all sides. For example: `style: [padding: 1]` means `[padding_top: 1, padding_bottom: 1, padding_left: 1, padding_right: 1]`

    * Two integers tuple - padding vertical and padding horizontal. For example: `style: [padding: {1, 2}]` means `[padding_top: 1, padding_bottom: 1, padding_left: 2, padding_right: 2]`

    * Four integers tuple - padding top, right, bottom, left respectively. For example: `style: [padding: {1, 2, 3, 4}]` means `[padding_top: 1, padding_bottom: 3, padding_left: 4, padding_right: 2]`

  ### Border

    * `:border` - whether to render a border around the rect. Defaults to `false`

    * `:border_top` - whether to render a top border. Defaults to `true` if `border` is `true`

    * `:border_bottom` - whether to render a bottom border. Defaults to `true` if `border` is `true`

    * `:border_left` - whether to render a left border. Defaults to `true` if `border` is `true`

    * `:border_right` - whether to render a right border. Defaults to `true` if `border` is `true`

    * `:border_color` - the color of the border. See [Color](#module-color) section for supported colors

  ### Color

    * `:color` - the color of the component text. The color value can be inherited from the parent component. If the color value is not specified, the component will inherit the color from the parent component

    * `:background_color` - the color of the component background

  The values for `:color` and `:background_color` is a single atom representing the color. Supported colors are:

    * `:white`
    * `:black`
    * `:grey`
    * `:dark_grey`
    * `:red`
    * `:dark_red`
    * `:green`
    * `:dark_green`
    * `:yellow`
    * `:dark_yellow`
    * `:blue`
    * `:dark_blue`
    * `:magenta`
    * `:dark_magenta`
    * `:cyan`
    * `:dark_cyan`
  """

  @doc """
  Generates a `Orange.Rect` struct

  ## Options

    * `:direction` - the direction to layout children `:row` or `:column` (default)

    * `:style` - style attributes for the rect. Supported keys are:

      * `:width` - see [Sizing](#module-sizing) section

      * `:height` - see [Sizing](#module-sizing) section

      * `:border` - see [Border](#module-border) section

      * `:padding` - see [Padding](#module-padding) section

      * `:color` - see [Color](#module-color) section

      * `:background_color` - see [Color](#module-color) section

    * `:title` - the title of the rect. If specified, it implies `border` is `true`

    * `:scroll_x` - the horizontal scroll offset

    * `:scroll_y` - the vertical scroll offset

  ## Children validation

  Rect only accepts `Orange.Rect` and `Orange.Line` as children. To provide better ergonomics, the macro will automatically wrap `Orange.Span` and string to `Orange.Line`. For example, the following code:

      rect do
        "Hello"
      end

      rect do
        span do
          "Hello"
        end
      end

    will both produce the result:

      %Orange.Rect{
        children: [
          %Orange.Line{
            children: [%Orange.Span{children: ["Hello"], attributes: []}],
            attributes: []
          }
        ],
        attributes: []
      }

  ## Examples

      iex> import Orange.Macro
      iex> rect style: [width: 5, border: true], direction: :row do
      ...>   "foo"
      ...>
      ...>   span do
      ...>     "bar"
      ...>   end
      ...> end
      %Orange.Rect{
        children: [
          %Orange.Line{
            children: [%Orange.Span{children: ["foo"], attributes: []}],
            attributes: []
          },
          %Orange.Line{
            children: [%Orange.Span{children: ["bar"], attributes: []}],
            attributes: []
          }
        ],
        attributes: [style: [width: 5, border: true], direction: :row]
      }
  """
  defmacro rect(attrs \\ [], do_block) do
    children = get_children(do_block)

    quote do
      children =
        unquote(children)
        |> Enum.reject(&is_nil/1)
        |> Orange.Macro.normalize_children(:rect)

      %Orange.Rect{
        children: children,
        attributes: unquote(attrs)
      }
    end
  end

  @doc """
  Generates a `Orange.Line` struct

  ## Options

    * `:style` - style attributes for the line. Supported keys are:

      * `:width` - see [Sizing](#module-sizing) section

      * `:height` - see [Sizing](#module-sizing) section

      * `:padding` - see [Padding](#module-padding) section

      * `:color` - see [Color](#module-color) section

      * `:background_color` - see [Color](#module-color) section

  ## Children validation

  Line only accepts `Orange.Span` as children. To provide better ergonomics, the macro will automatically wrap string to `Orange.Span`. For example, the following code:

      line do
        "Hello"
      end

    will produce the result:

      %Orange.Line{
        children: [%Orange.Span{children: ["Hello"], attributes: []}],
        attributes: []
      }

  ## Examples

      iex> import Orange.Macro
      iex> line style: [width: 5, color: :red] do
      ...>   span do
      ...>     "foo"
      ...>   end
      ...> end
      %Orange.Line{
        children: [%Orange.Span{children: ["foo"], attributes: []}],
        attributes: [style: [width: 5, color: :red]]
      }
  """
  defmacro line(attrs \\ [], do_block) do
    children = get_children(do_block)

    quote do
      children =
        unquote(children)
        |> Enum.reject(&is_nil/1)
        |> Orange.Macro.normalize_children(:line)

      %Orange.Line{
        children: children,
        attributes: unquote(attrs)
      }
    end
  end

  @doc """
  Generates a `Orange.Span` struct

  ## Options

    * `:style` - style attributes for the line. Supported keys are:

      * `:color` - see [Color](#module-color) section

      * `:background_color` - see [Color](#module-color) section

  ## Children validation

  Span only accepts a single string as children

  ## Examples

      iex> import Orange.Macro
      iex> span style: [color: :red] do
      ...>   "foo"
      ...> end
      %Orange.Span{children: ["foo"], attributes: [style: [color: :red]]}
  """
  defmacro span(attrs \\ [], do_block) do
    children = get_children(do_block)

    quote do
      %Orange.Span{
        children: unquote(children),
        attributes: unquote(attrs)
      }
    end
  end

  @doc false
  def normalize_children(children, :rect) when is_list(children) do
    for child <- List.flatten(children) do
      case child do
        text when is_binary(text) ->
          span = %Orange.Span{children: [text]}

          %Orange.Line{children: [span]}

        span when is_struct(span, Orange.Span) ->
          %Orange.Line{children: [span]}

        other ->
          other
      end
    end
  end

  @doc false
  def normalize_children(children, :line) when is_list(children) do
    for child <- List.flatten(children) do
      case child do
        text when is_binary(text) ->
          %Orange.Span{children: [text]}

        other ->
          other
      end
    end
  end

  defp get_children(do_block) do
    case do_block[:do] do
      {:__block__, _, children} -> children
      child -> [child]
    end
    |> Enum.map(&Macro.expand(&1, __ENV__))
  end
end
