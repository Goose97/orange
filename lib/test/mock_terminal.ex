defmodule Orange.Test.MockTerminal do
  @moduledoc false

  # Mock terminal for testing
  # Users can setup the mock terminal with mock events and terminal size
  # Draw function will store the rendered buffers and can be accessed with `get_drawn_buffers/0`

  @behaviour Orange.Terminal

  def setup(opts) do
    # We store in ETS table so that we can access data from any processes
    :ets.new(__MODULE__.Storage, [:set, :public, :named_table])
    :ets.insert(__MODULE__.Storage, {:buffers, []})

    terminal_size = Keyword.get(opts, :terminal_size)
    if terminal_size, do: :ets.insert(__MODULE__.Storage, {:terminal_size, terminal_size})

    events = Keyword.get(opts, :events)
    stop_after_last_event = Keyword.get(opts, :stop_after_last_event, true)

    if events,
      do:
        :ets.insert(
          __MODULE__.Storage,
          {:events, events, :counters.new(1, []), stop_after_last_event}
        )
  end

  def get_drawn_buffers() do
    [{_, buffers}] = :ets.lookup(__MODULE__.Storage, :buffers)
    buffers
  end

  @impl true
  def draw(buffer, _previous_buffer \\ nil) do
    [{_, buffers}] = :ets.lookup(__MODULE__.Storage, :buffers)
    :ets.insert(__MODULE__.Storage, {:buffers, buffers ++ [buffer]})
  end

  @impl true
  def poll_event() do
    case :ets.lookup(__MODULE__.Storage, :events) do
      [{_, events, counter, stop_after_last_event}] ->
        next_event(events, counter, stop_after_last_event)

      _ ->
        Process.sleep(:infinity)
    end
  end

  defp next_event(events, counter, stop_after_last_event) do
    index = :counters.get(counter, 1)
    :counters.add(counter, 1, 1)
    event = Enum.at(events, index)

    case event do
      {:wait, ms} ->
        Process.sleep(ms)
        next_event(events, counter, stop_after_last_event)

      nil ->
        if stop_after_last_event, do: Orange.stop()
        Process.sleep(:infinity)

      _ ->
        event
    end
  end

  @impl true
  def enter_alternate_screen(), do: :ok

  @impl true
  def leave_alternate_screen(), do: :ok

  @impl true
  def enable_raw_mode(), do: :ok

  @impl true
  def disable_raw_mode(), do: :ok

  @impl true
  def show_cursor(), do: :ok

  @impl true
  def hide_cursor(), do: :ok

  @impl true
  def clear(), do: :ok

  @impl true
  def terminal_size() do
    case :ets.lookup(__MODULE__.Storage, :terminal_size) do
      [{_, size}] -> size
      _ -> {0, 0}
    end
  end
end
