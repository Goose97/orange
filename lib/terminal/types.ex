defmodule Orange.Terminal.KeyEvent do
  @moduledoc """
  Terminal keyboard events.

  See `key_code/0` below for supported keys.
  """

  @type key_code ::
          :backspace
          | :enter
          | :left
          | :right
          | :up
          | :down
          | :home
          | :end
          | :page_up
          | :page_down
          | :tab
          | :back_tab
          | :delete
          | :insert
          | :f1
          | :f2
          | :f3
          | :f4
          | :f5
          | :f6
          | :f7
          | :f8
          | :f9
          | :f10
          | :f11
          | :f12
          | :null
          | :esc
          | :caps_lock
          | :scroll_lock
          | :num_lock
          | :print_screen
          | :pause
          | :menu
          | :keypad_begin
          | {:char, String.t()}

  @type key_modifier :: :shift | :ctrl | :alt | :super | :hyper

  @type t :: %__MODULE__{
          code: key_code,
          modifiers: [key_modifier]
        }

  defstruct [:code, :modifiers]
end

defmodule Orange.Terminal.ResizeEvent do
  @moduledoc """
  Terminal resize event.
  """

  @type t :: %__MODULE__{
          width: non_neg_integer,
          height: non_neg_integer
        }

  defstruct [:width, :height]
end
