defmodule Orange.Component.VerticalScrollableRect do
  @moduledoc """
  A component that renders a vertical scrollable rectangle. When the container is overflown, a scrollbar is rendered.

  ## Attributes

    - `:height` - The height of the container rect. This attribute is required.
    - `:content_height` - The height of the inner content. This attribute is required.
    - `:scroll_offset` - The vertical scroll offset. This attribute is required.
    - `:children` - The children of the container rect. This attribute is required.
    - `:title` - The title of the scrolling box. This attribute is optional.

  ## Examples

      defmodule Example do
        @behaviour Orange.Component

        import Orange.Macro

        @impl true
        def init(_attrs), do: %{state: nil}

        @impl true
        def render(_state, attrs, _update) do
          total_items = 30

          rect style: [width: 20, height: 20, border: attrs[:highlight]] do
            {
              Orange.Component.VerticalScrollableRect,
              height: 20,
              content_height: total_items,
              scroll_offset: 5,
              children: for(i <- 1..total_items, do: "Item \#{i}")
            }
          end
        end
      end

    ![rendered result](assets/vertical-scrollable-rect-example.png)

    For more examples, see `examples/scrollable_rect.exs`.
  """

  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(_attrs), do: %{state: nil}

  @impl true
  def render(_state, attrs, _update) do
    overflow = overflow?(attrs)
    width = if overflow, do: "calc(100% - 1)", else: "100%"

    scrolling_box_style = [
      width: width,
      height: "100%",
      border: true,
      border_right: !overflow
    ]

    scrolling_box_style = Keyword.merge(attrs[:style] || [], scrolling_box_style)

    rect direction: :row, style: [height: "100%"] do
      rect style: scrolling_box_style, title: attrs[:title], scroll_y: scroll_offset(attrs) do
        attrs[:children]
      end

      if overflow, do: scroll_bar(attrs)
    end
  end

  defp scroll_offset(attrs) do
    if overflow?(attrs) do
      # Minus two arrows at two ends
      max = attrs[:content_height] - (attrs[:height] - 2)
      min(attrs[:scroll_offset], max)
    else
      0
    end
  end

  defp overflow?(attrs), do: attrs[:content_height] > attrs[:height] - 2

  defp scroll_bar(attrs) do
    # Minus two arrows at two ends
    # Due to scrolling, we only see a portion of the content at one time. This is the height of that portion
    scroll_bar_track = attrs[:height] - 2
    content_viewport_height = scroll_bar_track

    scroll_thumb_height =
      round(content_viewport_height / attrs[:content_height] * scroll_bar_track)

    total_scrolled = scroll_offset(attrs) + content_viewport_height
    # Important variant that we need to preserve here:
    # a. When the scroll_offset is 0, the scroll thumb MUST be at the top of the track
    # b. When the scroll_offset is maximum (we can no longer scroll down), the scroll thumb MUST
    # be at the bottom of the track
    scroll_thumb_end = round(total_scrolled / attrs[:content_height] * scroll_bar_track)
    scroll_thumb_start = scroll_thumb_end - scroll_thumb_height

    rect style: [width: 1], direction: :column do
      [
        "▲",
        List.duplicate("│", scroll_thumb_start),
        List.duplicate("█", scroll_thumb_height),
        List.duplicate("│", scroll_bar_track - scroll_thumb_end),
        "▼"
      ]
      |> List.flatten()
    end
  end
end
