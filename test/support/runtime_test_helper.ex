defmodule Orange.RuntimeTestHelper do
  import Mox

  def dry_render(component) do
    # Temporary ets table to store the rendered buffers produced by `mock_draw/2`
    :ets.new(__MODULE__.Buffers, [:set, :public, :named_table])
    :ets.insert(__MODULE__.Buffers, {:buffers, []})

    {:ok, pid} = Orange.Runtime.start(component)
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    end

    [{_, buffers}] = :ets.lookup(__MODULE__.Buffers, :buffers)
    buffers
  end

  def dry_render_once(component) do
    # Temporary ets table to store the rendered buffers produced by `mock_draw/2`
    :ets.new(__MODULE__.Buffers, [:set, :public, :named_table])
    :ets.insert(__MODULE__.Buffers, {:buffers, []})

    {:ok, pid} = Orange.Runtime.start(component)
    Orange.Runtime.stop()

    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    end

    [{_, [buffer]}] = :ets.lookup(__MODULE__.Buffers, :buffers)
    buffer
  end

  def setup_mock_terminal(mock_terminal, opts) do
    terminal_size = Keyword.get(opts, :terminal_size)
    if terminal_size, do: stub(mock_terminal, :terminal_size, fn -> terminal_size end)

    events = Keyword.get(opts, :events)

    if events do
      event_counter = :counters.new(1, [])

      stub(mock_terminal, :poll_event, fn -> next_event(events, event_counter) end)
    else
      stub(mock_terminal, :poll_event, fn -> Process.sleep(:infinity) end)
    end

    nullify_terminal_api(mock_terminal)
    stub(mock_terminal, :draw, &mock_draw/2)
  end

  def next_event(events, counter) do
    index = :counters.get(counter, 1)
    :counters.add(counter, 1, 1)
    event = Enum.at(events, index)

    case event do
      {:wait, ms} ->
        Process.sleep(ms)
        next_event(events, counter)

      # If there are no more events, mimic the blocking behavior of `poll_event/0`
      nil ->
        Process.sleep(:infinity)

      _ ->
        event
    end
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
    stub(mock_terminal, :leave_alternate_screen, fn -> :ok end)
    stub(mock_terminal, :enable_raw_mode, fn -> :ok end)
    stub(mock_terminal, :disable_raw_mode, fn -> :ok end)
    stub(mock_terminal, :show_cursor, fn -> :ok end)
    stub(mock_terminal, :hide_cursor, fn -> :ok end)
  end

  defp mock_draw(buffer, _previous_buffer) do
    [{_, buffers}] = :ets.lookup(__MODULE__.Buffers, :buffers)
    :ets.insert(__MODULE__.Buffers, {:buffers, buffers ++ [buffer]})
  end
end
