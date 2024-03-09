defmodule Orange.RuntimeTestHelper do
  import Mox

  def dry_render(component) do
    try do
      Orange.Runtime.start(component)
    catch
      :stop -> :ok
    end

    Process.get(:buffers)
  end

  def setup_mock_terminal(mock_terminal, opts) do
    terminal_size = Keyword.get(opts, :terminal_size)
    if terminal_size, do: stub(mock_terminal, :terminal_size, fn -> terminal_size end)

    nullify_terminal_api(mock_terminal)
    stub(mock_terminal, :draw, &mock_draw/2)
  end

  def setup_mock_event_manager(mock_event_manager, opts) do
    events = Keyword.get(opts, :events, [])
    Mox.stub_with(mock_event_manager, Orange.Runtime.EventManager)

    stub(mock_event_manager, :start_background_event_poller, fn ->
      Enum.each(events, fn event ->
        send(self(), {:event, event})
      end)
    end)
  end

  defp nullify_terminal_api(mock_terminal) do
    stub(mock_terminal, :enter_alternate_screen, fn -> :ok end)
    stub(mock_terminal, :enable_raw_mode, fn -> :ok end)
    stub(mock_terminal, :show_cursor, fn -> :ok end)
    stub(mock_terminal, :hide_cursor, fn -> :ok end)
  end

  defp mock_draw(buffer, _previous_buffer) do
    buffers = Process.get(:buffers, [])
    Process.put(:buffers, buffers ++ [buffer])
  end
end
