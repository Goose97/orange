defmodule Orange.Component.Input do
  # TODO: Show cursor for input

  @moduledoc """
  An uncontrolled input component.

  ## Attributes

    * `:on_submit` - A callback triggered when input is submitted. This attribute is required.
    * `:submit_key` - The keyboard key that will trigger submission. This attribute is optional and defaults to :enter. See `Orange.Terminal.KeyEvent` for supported values.
    * `:on_exit` - A callback triggered when input is exited. This attribute is optional.
    * `:exit_key` - The keyboard key that will unfocus the input. This attribute is optional and defaults to :esc. See `Orange.Terminal.KeyEvent` for supported values.
    > #### Info {: .info}
    >
    > The `:submit_key` and `:exit_key` can not be `:backspace` as it is reserved for deleting characters.

    * `:auto_focus` - Whether to focus automatically after mount. This attribute is optional. If true, the `:id` attribute is required and the input will unfocus after submission.
    * `:prefix` - The input prefix string. This attribute is optional.
    * `:style` - The component style. This attribute is optional.

  ## Examples

      defmodule Example do
        @behaviour Orange.Component

        import Orange.Macro

        @impl true
        def init(_attrs), do: %{state: %{search_value: ""}}

        @impl true
        def render(state, _attrs, update) do
          rect style: [width: 50, height: 20] do
            {
              Orange.Component.Input,
              id: :input,
              on_submit: fn value -> update.(%{state | search_value: value}) end,
              submit_key: {:char, "x"},
              prefix: "Enter search value:",
              auto_focus: true
            }

            rect do
              "Search value: \#{state.search_value}"
            end
          end
        end
      end

    ![rendered result](assets/input-example.gif)
  """

  @behaviour Orange.Component

  import Orange.Macro

  @impl true
  def init(attrs) do
    if attrs[:auto_focus] && !attrs[:id],
      do: raise("#{__MODULE__}: Expected an :id attribute when :auto_focus is true")

    %{state: %{input: ""}}
  end

  @impl true
  def handle_event(event, state, attrs, _update) do
    submit_key = Keyword.get(attrs, :submit_key, :enter)
    exit_key = Keyword.get(attrs, :exit_key, :esc)

    case event do
      %Orange.Terminal.KeyEvent{code: ^submit_key} ->
        attrs[:on_submit].(state.input)
        if attrs[:auto_focus], do: Orange.unfocus(attrs[:id])

        {:update, state}

      %Orange.Terminal.KeyEvent{code: ^exit_key} ->
        if attrs[:on_exit], do: attrs[:on_exit].()
        if attrs[:id], do: Orange.unfocus(attrs[:id])

        {:update, state}

      %Orange.Terminal.KeyEvent{code: {:char, char}} ->
        state = update_in(state, [:input], &(&1 <> char))
        {:update, state}

      %Orange.Terminal.KeyEvent{code: :backspace} ->
        state =
          if String.length(state.input) > 0,
            do: update_in(state, [:input], &String.slice(&1, 0, String.length(&1) - 1)),
            else: state

        {:update, state}

      _ ->
        :noop
    end
  end

  @impl true
  def after_mount(_state, attrs, _update) do
    if attrs[:auto_focus], do: Orange.focus(attrs[:id])
  end

  @impl true
  def render(state, attrs, _update) do
    text = state.input
    text = if attrs[:prefix], do: "#{attrs[:prefix]} #{text}", else: text

    rect style: Keyword.get(attrs, :style, []) do
      text
    end
  end
end
