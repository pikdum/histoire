defmodule Histoire.Nyaa.Jobs do
  @moduledoc false

  alias Histoire.Nyaa.{Parser, Workers.EnrichTorrent}

  def enqueue_torrent(torrent_url, opts \\ []) do
    with {:ok, id} <- Parser.torrent_id(torrent_url) do
      priority = Keyword.get(opts, :priority, 3)
      schedule_in = Keyword.get(opts, :schedule_in, 0)

      %{"id" => id}
      |> EnrichTorrent.new(priority: priority, schedule_in: schedule_in)
      |> Oban.insert()
    end
  end
end
