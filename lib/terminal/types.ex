defmodule Orange.Terminal.KeyEvent do
  @moduledoc false

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
