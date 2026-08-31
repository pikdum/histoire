defmodule Histoire.Nyaa.BackfillTest do
  use Histoire.DataCase, async: true
  use Oban.Testing, repo: Histoire.Repo

  alias Histoire.Catalog.SubsPleaseNyaaDownloadOverride
  alias Histoire.Nyaa.{Backfill, Enrichment}
  alias Histoire.Nyaa.Workers.EnrichTorrent
  alias Histoire.SubsPlease.{Download, Release, Show}

  test "enqueues the override for the highest-resolution batch download" do
    now = ~U[2026-08-30 12:00:00Z]

    show = Show.upsert!(%{id: 128, slug: "maiko-san", name: "Maiko-san", fetched_at: now})

    release =
      Release.upsert!(%{
        show_id: show.id,
        kind: :batch,
        name: "Maiko-san - 01-12",
        episode: "01-12",
        released_at: now
      })

    _download_720 =
      Download.upsert!(%{
        release_id: release.id,
        resolution: "720",
        torrent_url: "https://nyaa.si/view/1511343/torrent"
      })

    download_1080 =
      Download.upsert!(%{
        release_id: release.id,
        resolution: "1080",
        torrent_url: "https://nyaa.si/view/1511344/torrent"
      })

    {:ok, _torrent} =
      Enrichment.store(1_490_919, "https://nyaa.si/view/1490919", %{
        title: "Maiko-san 1080p",
        magnet_uri: "magnet:?xt=urn:btih:replacement",
        files: [%{path: "Maiko-san - 01.mkv", size: "1.2 GiB"}]
      })

    SubsPleaseNyaaDownloadOverride.put!(%{
      subsplease_download_id: download_1080.id,
      nyaa_id: 1_490_919
    })

    assert {:ok, 1} = Backfill.enqueue_batches()
    assert_enqueued worker: EnrichTorrent, args: %{"id" => 1_490_919}, priority: 0
    refute_enqueued worker: EnrichTorrent, args: %{"id" => 1_511_344}
  end
end
