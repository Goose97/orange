defmodule Orange.Component.Modal do
  @moduledoc """
  A modal/dialog component which renders an overlay in the middle of the viewport.

  ## Attributes

    - `:open` - Whether the modal is open or not. This attribute is required.
    - `:offset_x` - The offset from the left and right edge of the screen. This attribute is required.
    - `:offset_y` - The offset from the top and bottom edge of the screen. This attribute is required.
    > #### Info {: .info}
    >
    > When the offset_x/y is too big for the terminal size, the modal will not be rendered.

    - `:children` - A list of elements used as content of the modal. This attribute is optional.
    - `:title` - The title of the modal. See `Orange.Macro.rect/2` for supported values. This attribute is optional.
    - `:style` - The modal style. See `Orange.Macro.rect/2` for supported values. This attribute is optional.

  ## Examples

      defmodule Example do
        @behaviour Orange.Component

        import Orange.Macro

        @impl true
        def init(_attrs), do: %{state: %{search_value: ""}}

        @impl true
        def render(state, _attrs, update) do
          modal_content =
            rect do
              "foo"
              "bar"
            end

          rect do
            rect do
              "Displaying modal..."
            end

            {
              Orange.Component.Modal,
              offset_x: 8,
              offset_y: 4,
              children: [modal_content],
              open: true
            }
          end
        end
      end

    ![rendered result](assets/modal-example.png)
  """

  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: nil}

  @impl true
  def render(_state, attrs, _update) do
    {width, height} = terminal_impl().terminal_size()

    offset_x = attrs[:offset_x]
    offset_y = attrs[:offset_y]

    style =
      Keyword.merge(
        Keyword.get(attrs, :style, []),
        border: true
      )

    # Plus 2 for the border
    if attrs[:open] && width > offset_x * 2 + 2 && height > offset_y * 2 + 2 do
      rect position: {:fixed, offset_y, offset_x, offset_y, offset_x},
           style: style,
           title: attrs[:title] do
        attrs[:children]
      end
    end
  end

  defp terminal_impl(), do: Application.get_env(:orange, :terminal, Orange.Terminal)
end
