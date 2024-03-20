defmodule Orange.Runtime.EventPoller do
  @moduledoc false

  alias Orange.Terminal

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args}
    }
  end

  def start_link(params),
    do: {:ok, spawn_link(fn -> poll_event_loop(params[:event_receiver]) end)}

  defp poll_event_loop(event_receiver) do
    event = terminal_impl().poll_event()
    send(event_receiver, {:event, event})
    poll_event_loop(event_receiver)
  end

  defp terminal_impl(), do: Application.get_env(:orange, :terminal, Terminal)
end
