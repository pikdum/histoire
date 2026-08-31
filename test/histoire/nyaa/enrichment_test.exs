defmodule Histoire.Nyaa.EnrichmentTest do
  use Histoire.DataCase, async: true

  alias Histoire.Nyaa.{Enrichment, Torrent}

  test "stores a parsed torrent and returns the loaded torrent directly" do
    parsed = %{
      title: "[SubsPlease] Example - 01-12 (1080p) [Batch]",
      magnet_uri: "magnet:?xt=urn:btih:0123456789abcdef0123456789abcdef01234567",
      files: [
        %{path: "[SubsPlease] Example - 01 (1080p) [ABCDEF01].mkv", size: "1.2 GiB"},
        %{path: "[SubsPlease] Example - 02 (1080p) [ABCDEF02].mkv", size: "1.3 GiB"}
      ]
    }

    assert {:ok, %Torrent{id: 123, files: files}} =
             Enrichment.store(123, "https://nyaa.si/view/123", parsed)

    assert Enum.map(files, & &1.path) == Enum.map(parsed.files, & &1.path)
  end
end
