defmodule Orange.Macro do
  @moduledoc """
  Macros for creating Orange primitive components

  Currently, Orange supports only one primitive component: `rect` (rectangle). Primitive components are
  the building blocks of Orange applications. They can be used to construct more complex components.

  For layout management, Orange leverages the [taffy](https://docs.rs/taffy/latest/taffy/) Rust crate.
  It supports two layouts in the CSS specifications:

    * `flex`: Flexible box layout
    * `grid`: Grid layout system

  ## Examples

  Macro provides an ergonomic way to create Orange components. For example, the following code:

      rect style: [width: 12, border: true, flex_direction: :row] do
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
        attributes: [style: [width: 12, border: true, flex_direction: :row]]
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

  ### Display

  The `:display` property controls how children are laid out. Supported values are:

    * `:flex` (default) - Flexible box layout
    * `:grid` - Grid layout

  #### Flex Layout

  When display is `:flex`, the following properties control the layout:

    * `:flex_direction` - Direction of the flex container. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/flex-direction) for more info. Supported values:

      * `:row` (default) - Main axis is horizontal. Cross axis is vertical.

      * `:column` - Main axis is vertical. Cross axis is horizontal.

    * `:flex_grow` - How much the component grows relative to siblings when there is extra space. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/flex-grow) for more info.

    * `:flex_shrink` - How much the component shrinks relative to siblings when space is limited. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/flex-shrink) for more info.

    * `:justify_content` - Alignment along the main axis. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/justify-content) for more info. Supported values:

      * `:start` (default) - Pack items at the start

      * `:end` - Pack items at the end

      * `:center` - Center items

      * `:space_between` - Evenly space items with first/last at edges

      * `:space_around` - Evenly space items with equal space around

      * `:space_evenly` - Evenly space items with equal space between

      * `:stretch` - Stretch items to fill container

    * `:align_items` - Alignment along the cross axis. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/align-items) for more info. Supported values:

      * `:start` (default) - Align items at the start

      * `:end` - Align items at the end

      * `:center` - Center items

      * `:space_between` - Evenly space items with first/last at edges

      * `:space_around` - Evenly space items with equal space around

      * `:space_evenly` - Evenly space items with equal space between

      * `:stretch` - Stretch items to fill container

  #### Grid Layout

  When display is `:grid`, the following properties control the layout:

    * `:grid_template_rows` - defines the size of the rows in the grid. Takes a list of track sizes. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/grid-template-rows) for more info.
    * `:grid_template_columns` - defines the size of the columns in the grid. Takes a list of track sizes. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/grid-template-columns) for more info.

  Track sizes can be:

    * An integer - fixed number of cells

    * A percentage string - percentage of container size (e.g. "50%")

    * `{:fr, n}` - takes up n fraction of remaining space

    * `:auto` - sized based on content

    * `:min_content` - mimimum size to display the content

    * `:max_content` - maximum size to display the content

    * `{:repeat, count, size}` - repeats the size specification count times

  If no explicit rows/columns are defined, grid items will be put into implicitly created tracks, determined by:

    * `:grid_auto_rows` - defines the size of the implicitly created rows. Takes a list of track sizes (except the :repeat). See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/grid-auto-rows) for more info.
    * `:grid_auto_columns` - defines the size of the implicitly created columns. Takes a list of track sizes (except the :repeat). See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/grid-auto-columns) for more info.

  Child items can be positioned in the grid using:

    * `:grid_row` - specifies grid row placement. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/grid-row) for more info.

    * `:grid_column` - specifies grid column placement. See [MDN docs](https://developer.mozilla.org/en-US/docs/Web/CSS/grid-column) for more info.

  Grid placement values can be:

    * An integer - places at specific grid line

    * `{:span, n}` - spans n tracks

    * `:auto` - automatic placement

    * `{start, end}` - explicit start/end placement where start/end is a grid placement (e.g. {2, {:span, 3}} means
    start at row/column index 2 and ends at index 5)

      ```
      rect style: [
        display: :grid,
        grid_template_columns: [100, {:fr, 1}, "50%"],
        grid_template_rows: ["33%", {:repeat, 2, {:fr, 1}}]
      ] do
        rect style: [grid_column: {1, 3}] do
          "Header"
        end
        rect style: [grid_row: {:span, 2}] do
          "Sidebar"
        end
      end
      ```

  #### Common properties

  Both `:flex` and `:grid` layouts support the following properties:

    * `:gap` - Sets spacing between items in both directions. Acts as a shorthand for both `:row_gap` and `:column_gap`. Takes an integer value.

    * `:row_gap` - Sets spacing between rows. Takes an integer value. If specified, overrides the row spacing set by `:gap`.

    * `:column_gap` - Sets spacing between columns. Takes an integer value. If specified, overrides the column spacing set by `:gap`.

  ### Sizing

    * `:width` - the width of the component

    * `:height` - the height of the component

  The values for `width` and `height` can be:

    * An integer - the number of cells in the terminal. For example: `style: [width: 10]`

    * A percentage string - the size is equal to the given percentage of the parent size. For example: `style: [width: "50%"]`

  ### Padding

  Padding for the render box's inner content. The values for `padding` can be:

    * One integer - padding for all sides. For example: `style: [padding: 1]` means `[padding_top: 1, padding_bottom: 1, padding_left: 1, padding_right: 1]`

    * Two integers tuple - padding vertical and padding horizontal. For example: `style: [padding: {1, 2}]` means `[padding_top: 1, padding_bottom: 1, padding_left: 2, padding_right: 2]`

    * Four integers tuple - padding top, right, bottom, left respectively. For example: `style: [padding: {1, 2, 3, 4}]` means `[padding_top: 1, padding_bottom: 3, padding_left: 4, padding_right: 2]`

  ### Margin

  Margin creates space around the render box. The values for `margin` follow the same format as padding:

    * One integer - margin for all sides. For example: `style: [margin: 1]` means `[margin_top: 1, margin_bottom: 1, margin_left: 1, margin_right: 1]`

    * Two integers tuple - margin vertical and margin horizontal. For example: `style: [margin: {1, 2}]` means `[margin_top: 1, margin_bottom: 1, margin_left: 2, margin_right: 2]`

    * Four integers tuple - margin top, right, bottom, left respectively. For example: `style: [margin: {1, 2, 3, 4}]` means `[margin_top: 1, margin_bottom: 3, margin_left: 4, margin_right: 2]`

  ### Border

    * `:border` - whether to render a border around the rect. Defaults to `false`

    * `:border_top` - whether to render a top border. Defaults to `true` if `border` is `true`

    * `:border_bottom` - whether to render a bottom border. Defaults to `true` if `border` is `true`

    * `:border_left` - whether to render a left border. Defaults to `true` if `border` is `true`

    * `:border_right` - whether to render a right border. Defaults to `true` if `border` is `true`

    * `:border_color` - the color of the border. See [Color](#module-color) section for supported colors

    * `:border_style` - the style of the border. Supported styles are:

      * `:default` (default) - normal border

      * `:round_corners` - border with round corners

      * `:dashed` - dashed border

      * `:double` - double border

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

  ### Scroll bar

    * `:scroll_bar` - controls the visibility of scroll bars when scrolling is enabled. Supported values are:

      * `:visible` (default) - scroll bars are shown when content is scrollable

      * `:hidden` - scroll bars are never shown, even when content is scrollable

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

    * `{:absolute, top, right, bottom, left}` - positions the rect at absolute coordinates relative to its parent element's edges. For example:

      ```
      rect position: {:absolute, 1, 2, 1, 2} do
        "Absolute position"
      end
      ```

      This will position the rect 1 cell from the parent's top edge, 2 cells from its right edge, 1 cell from its bottom edge, and 2 cells from its left edge.

      > #### Warning {: .warning}
      >
      > At least left or right must be specified, and at least top or bottom must be specified.
      >
      > Absolute position can't be used on root element.
  """

  @doc """
  Generates a `Orange.Rect` struct

  ## Options

    * `:style` - style attributes for the rect. Supported keys are:

      * `:width` - see [Sizing](#module-sizing) section

      * `:height` - see [Sizing](#module-sizing) section

      * `:border` - see [Border](#module-border) section

      * `:padding` - see [Padding](#module-padding) section

      * `:color` - see [Color](#module-color) section

      * `:background_color` - see [Color](#module-color) section

      * `:scroll_bar` - see [Border](#module-border) section

      * `:display` - see [Display][#module-display] section

      * `:flex_direction` - available for `:flex` display. See [Flex Layout](#module-flex-layout) section

      * `:justify_content` - available for `:flex` display. See [Flex Layout](#module-flex-layout) section

      * `:align_items` - available for `:flex` display. See [Flex Layout](#module-flex-layout) section

      * `:flex_grow` - available for `:flex` display. See [Flex Layout](#module-flex-layout) section

      * `:flex_shrink` - available for `:flex` display. See [Flex Layout](#module-flex-layout) section

      * `:grid_template_rows` - available for `:grid` display. See [Grid Layout](#module-grid-layout) section

      * `:grid_template_columns` - available for `:grid` display. See [Grid Layout](#module-grid-layout) section

      * `:grid_row` - available for `:grid` display. See [Grid Layout](#module-grid-layout) section

      * `:grid_column` - available for `:grid` display. See [Grid Layout](#module-grid-layout) section

    * `:title` - the title of the rect. If specified, it implies `border` is `true`. The title can be a string, a rect element, or a map. Supported keys for map are:

      * `:text` - the title text. Accepts a string or a rect element. This field is required

      * `:offset` - an integer specifies the title offset from the edge. This field is optional and defaults to 0

      * `:align` - controls the alignment of the title. Supported values are:

        * `:left` (default) - aligns the title to the left edge of the rect

        * `:center` - centers the title in the rect

        * `:right` - aligns the title to the right edge of the rect

    * `:footer` - the footer of the rect. If specified, it implies `border` is `true`. The footer can be a string, a rect element, or a map. Supported keys for map are:

      * `:text` - the footer text. Accepts a string or a rect element. This field is required

      * `:offset` - an integer specifies the footer offset from the edge. This field is optional and defaults to 0

      * `:align` - controls the alignment of the footer. Supported values are:

        * `:left` - aligns the title to the left edge of the rect

        * `:center` - centers the title in the rect

        * `:right` (default) - aligns the title to the right edge of the rect

    * `:scroll_x` - the horizontal scroll offset

    * `:scroll_y` - the vertical scroll offset

    * `:position` - the position of the rect. See [Position](#module-position) section

    * `:background_text` - fill the rect's background with a text. Takes a string or a map with supported keys are:

      * `:text` - the background text. This field is required

      * `:color` - the background text color. This field is optional

      * `:text_modifiers` - the background text modifiers. See [Text modifiers](#module-text-modifiers) section. This field is optional

        For example:

        ```
        rect style: [width: 10, height: 3], background_text: "-" do
          "Hello"
        end
        ```

        will render:

        ```
        Hello-----
        ----------
        ----------
        ```

        The background text will be visible in empty areas of the rect, creating a repeating pattern effect.

  ## Examples

      iex> import Orange.Macro
      iex> rect style: [width: 5, border: true, flex_direction: :row] do
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
        attributes: [style: [width: 5, border: true, flex_direction: :row]]
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
