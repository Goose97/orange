defmodule Orange.Macro do
  @moduledoc """
  Macros for creating Orange primitive components

  Currently, Orange supports only one primitive component:
    * `rect` for creating a rectangle

  ## Examples

  TODO: double check the examples
  Macro provides an ergonomic way to create Orange components. For example, the following code:

      rect style: [width: 12, border: true], direction: :row do
        rect style: [color: :red] do
          "Hello"
        end

        rect do
          "World"
        end
      end

  will produce the following struct:

      %Orange.Rect{
        children: [
          %Orange.Rect{children: ["Hello"], attributes: [style: [color: :red]]},
          %Orange.Rect{children: ["World"], attributes: []}
        ],
        attributes: [style: [width: 12, border: true], direction: :row]
      }

  ## Components children

  Orange components can have children, provided by the do block. The syntax took inspiration from HTML:

      rect do
        rect do
          "Hello"
        end

        rect do
          "World"
        end
      end

  The children can also be a list of components. This is useful when you want to render a collection of components. For example:

      rect do
        [
          rect do
            "Hello"
          end,

          rect do
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

  ### Text modifiers

  An array of modifiers which adjust the text style. Supported modifiers are:

    * `:bold`
    * `:dim`
    * `:italic`
    * `:underline`
    * `:strikethrough`

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

  ### Line wrap

  By default, the text will wrap to the next line if it exceeds the width of the component. To disable this behavior, set the `:line_wrap` attribute to `false`

  ## Position

  Rect elements support positioning. Supported values are:

    * `{:fixed, top, right, bottom, left}` - the rect will be fixed at the given position. The values are offset to the respective edge of the screen. For example:

      ```
      rect position: {:fixed, 1, 2, 1, 2} do
        "Fixed position"
      end
      ```

      will render:

      ![rendered result](assets/fixed-position-example.png)
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

    * `:title` - the title of the rect. If specified, it implies `border` is `true`. The title can be a string or a map with supported keys are:

      * `:text` - the title text. This field is required

      * `:color` - the title color. This field is optional

      * `:text_modifiers` - the title text modifiers. See [Text modifiers](#module-text-modifiers) section. This field is optional

      * `:offset` - an integer specifies the title offset from the left edge. This field is optional and defaults to 0

    * `:scroll_x` - the horizontal scroll offset

    * `:scroll_y` - the vertical scroll offset

    * `:position` - the position of the rect. See [Position](#module-position) section

  ## Examples

      iex> import Orange.Macro
      iex> rect style: [width: 5, border: true], direction: :row do
      ...>   "foo"
      ...>
      ...>   rect do
      ...>     "bar"
      ...>   end
      ...> end
      %Orange.Rect{
        children: [
          %Orange.Rect{children: ["foo"], attributes: []},
          %Orange.Rect{children: ["bar"], attributes: []}
        ],
        attributes: [style: [width: 5, border: true], direction: :row]
      }
  """
  defmacro rect(attrs \\ [], do_block) do
    children =
      case do_block[:do] do
        {:__block__, _, children} -> children
        child -> [child]
      end
      |> Enum.map(&Macro.expand(&1, __ENV__))

    quote do
      children = Enum.reject(unquote(children), &is_nil/1) |> List.flatten()

      %Orange.Rect{
        children: children,
        attributes: unquote(attrs)
      }
    end
  end
end
