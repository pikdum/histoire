defmodule Histoire.Nyaa.Jobs do
  @moduledoc false

  alias Histoire.Nyaa.{Parser, Workers.EnrichTorrent}

  def enqueue_torrent(target, opts \\ [])

  def enqueue_torrent(id, opts) when is_integer(id) and id > 0 do
    priority = Keyword.get(opts, :priority, 3)
    schedule_in = Keyword.get(opts, :schedule_in, 0)

    %{"id" => id}
    |> EnrichTorrent.new(priority: priority, schedule_in: schedule_in)
    |> Oban.insert()
  end

  def enqueue_torrent(torrent_url, opts) when is_binary(torrent_url) do
    with {:ok, id} <- Parser.torrent_id(torrent_url) do
      enqueue_torrent(id, opts)
    end
  end

  def enqueue_torrent(_target, _opts), do: {:error, :invalid_nyaa_url}
end
