defmodule Orange.Runtime.RenderLoop.ValidationTest do
  use ExUnit.Case
  import Mox

  alias Orange.{Terminal, Runtime, RuntimeTestHelper}

  setup_all do
    Mox.defmock(Orange.MockTerminal, for: Terminal)
    Application.put_env(:orange, :terminal, Orange.MockTerminal)

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  @tag :capture_log
  test "Invalid rect children" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 6}
    )

    %RuntimeError{message: message} = catch_render_error(__MODULE__.InvalidRect)

    assert message =~
             ~r/Invalid child of rect. Expected a rect, a line, or a custom component/
  end

  @tag :capture_log
  test "Invalid line children" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 6}
    )

    %RuntimeError{message: message} = catch_render_error(__MODULE__.InvalidLine)

    assert message =~
             ~r/Invalid child of line. Expected a span, or a custom component/
  end

  @tag :capture_log
  test "Invalid span children" do
    RuntimeTestHelper.setup_mock_terminal(Orange.MockTerminal,
      terminal_size: {20, 6}
    )

    %RuntimeError{message: message} = catch_render_error(__MODULE__.InvalidSpan)

    assert message =~
             ~r/Invalid child of span. Expected a single text child/
  end

  defp catch_render_error(component) do
    Process.flag(:trap_exit, true)
    %{start: {m, f, a}} = Runtime.RenderLoop.child_spec([component])
    {:ok, pid} = apply(m, f, a)
    Process.link(pid)
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    after
      2500 ->
        flunk("Expected the render loop process to exit, but it didn't")
    end

    receive do
      {:EXIT, _, {error, _}} ->
        error
    after
      0 ->
        flunk("Expected to receive an exit message, got nothing")
    end
  end

  defmodule InvalidRect do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, _attrs, _update) do
      rect do
        Orange.Runtime.RenderLoop.ValidationTest.Span
      end
    end
  end

  defmodule InvalidLine do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, _attrs, _update) do
      line do
        Orange.Runtime.RenderLoop.ValidationTest.Rect
      end
    end
  end

  defmodule InvalidSpan do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, _attrs, _update) do
      span do
        "foo"
        "bar"
      end
    end
  end

  defmodule Rect do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, _attrs, _update) do
      rect do
        "foo"
      end
    end
  end

  defmodule Span do
    @behaviour Orange.Component

    import Orange.Macro

    @impl true
    def init(_attrs), do: %{state: nil}

    @impl true
    def render(_state, _attrs, _update) do
      span do
        "foo"
      end
    end
  end
end
