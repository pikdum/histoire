defmodule AnimeData.SubsPlease.RateLimiter do
  @moduledoc """
  Serializes reservations for SubsPlease requests across all callers.

  The default interval is deliberately conservative because bulk refreshes are
  background work. Hot jobs use Oban priority to move ahead of bulk work, but
  they still pass through this same source-wide gate.
  """

  use GenServer

  @default_interval_ms 10_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def wait do
    GenServer.call(__MODULE__, :reserve, :infinity)
  end

  @impl GenServer
  def init(_opts) do
    {:ok, %{next_at: System.monotonic_time(:millisecond)}}
  end

  @impl GenServer
  def handle_call(:reserve, from, %{next_at: next_at} = state) do
    now = System.monotonic_time(:millisecond)
    reservation = max(now, next_at)
    delay = reservation - now

    interval =
      Application.get_env(:anime_data, :subsplease_request_interval_ms, @default_interval_ms)

    Process.send_after(self(), {:release, from}, delay)
    {:noreply, %{state | next_at: reservation + interval}}
  end

  @impl GenServer
  def handle_info({:release, from}, state) do
    GenServer.reply(from, :ok)
    {:noreply, state}
  end
end
