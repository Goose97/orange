defmodule Orange.Test do
  @moduledoc """
  Orange test framework.

  Orange provides a test framework to test your UI components. You can use `Orange.Test.render/1` to render a component
  and use `Orange.Test.Assertions` to assert on the rendered output.
  """

  @doc """
  Render a component and return a list of snapshots. You can provide a list of events to simulate events comming
  from the terminal.

  ## Options

    * `:terminal_size` - the size of the terminal. This option is required.

    * `:events` - a list of mock events from the terminal. These events will be consumed by Orange in the same order as they are specified. This option is optional. Supported event types:

      * `Orange.Terminal.KeyEvent` - simulates a key event
      * `Orange.Terminal.ResizeEvent` - simulates a terminal resize event
      * `{:wait, ms}` - wait for `ms` milliseconds
      * `{:function, fun}` - execute the given function

    * `:stop_after_last_event` - whether to stop the runtime after the last event is consumed. This option is optional. Defaults to `true`.

  ## Examples

      [snapshot1, snapshot2, snapshot3 | _] = Test.render({MyComponent, open: true},
        terminal_size: {20, 15},
        events: [
          %Terminal.KeyEvent{code: {:char, "f"}},
          %Terminal.KeyEvent{code: {:char, "q"}}
        ]
      )

      Orange.Test.Assertions.assert_content(snapshot1, "Expected content...")
      Orange.Test.Assertions.assert_background_color(snapshot2, 0, 1, :red)
      Orange.Test.Assertions.assert_color(snapshot3, 0, 1, :yellow)
  """
  def render(component, opts) do
    Application.put_env(:orange, :terminal, __MODULE__.MockTerminal)
    __MODULE__.MockTerminal.setup(opts)

    {:ok, pid} = Orange.Runtime.start(component)
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    end

    for buffer <- __MODULE__.MockTerminal.get_captured_buffers() do
      %__MODULE__.Snapshot{buffer: buffer}
    end
  end

  @doc """
  Render a component once and return the first snapshot.

  This is useful when you want to test the initial render of a component without any
  interaction or subsequent updates. It stops the runtime immediately after the first render.

  ## Options

  Takes the same options as `render/2`.

  ## Examples

      snapshot = Test.render_once({MyComponent, open: true}, terminal_size: {20, 15})
      assert_content(snapshot, "Expected content...")
  """
  def render_once(component, opts) do
    Application.put_env(:orange, :terminal, __MODULE__.MockTerminal)
    __MODULE__.MockTerminal.setup(opts)

    {:ok, pid} = Orange.Runtime.start(component)
    Orange.Runtime.stop()
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    end

    buffer = hd(__MODULE__.MockTerminal.get_drawn_buffers())
    %__MODULE__.Snapshot{buffer: buffer}
  end

  @doc """
  Render a component and catch any errors that occur during initialization.

  This is useful for testing error conditions and validation in component initialization.
  It returns the error that caused the render loop to exit.

  ## Options

  Takes the same options as `render/2`.

  ## Examples

      %RuntimeError{message: message} = Test.render_catch_error({MyComponent, invalid_prop: true}, terminal_size: {20, 6})
      assert message =~ "Expected error message"
  """
  def render_catch_error(component, opts) do
    Application.put_env(:orange, :terminal, __MODULE__.MockTerminal)
    __MODULE__.MockTerminal.setup(opts)
    Process.flag(:trap_exit, true)

    %{start: {m, f, a}} = Orange.Runtime.RenderLoop.child_spec([component])
    {:ok, pid} = apply(m, f, a)
    Process.link(pid)
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    after
      2500 ->
        ExUnit.Assertions.flunk("Expected the render loop process to exit, but it didn't")
    end

    receive do
      {:EXIT, _, {error, _}} ->
        error
    after
      0 ->
        ExUnit.Assertions.flunk("Expected to receive an exit message, got nothing")
    end
  end
end
