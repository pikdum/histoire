defmodule Histoire.Nyaa.ParserTest do
  use ExUnit.Case, async: true

  alias Histoire.Nyaa.Parser

  test "extracts a torrent id from Nyaa view and download URLs" do
    assert {:ok, 1_319_949} = Parser.torrent_id("https://nyaa.si/view/1319949")
    assert {:ok, 1_319_949} = Parser.torrent_id("https://nyaa.si/view/1319949/torrent")
    assert {:error, :invalid_nyaa_url} = Parser.torrent_id("https://example.test/view/1319949")
  end

  test "parses a batch magnet and video file list from a Nyaa page" do
    html = """
    <div class="panel panel-success">
      <div class="panel-heading"><h3 class="panel-title">[SubsPlease] Example (01-02) [Batch]</h3></div>
      <div class="panel-footer">
        <a class="card-footer-item" href="magnet:?xt=urn:btih:VS6Z5XS3WA2W6JGECOMYC5N2KVRIBJBD&amp;tr=udp%3A%2F%2Ftracker">Magnet</a>
      </div>
    </div>
    <div class="torrent-file-list panel-body">
      <ul>
        <li><a class="folder"><i class="fa fa-folder-open"></i>Example</a><ul>
          <li><i class="fa fa-file"></i>[SubsPlease] Example - 01 (1080p) [AAAA].mkv <span class="file-size">(1.2 GiB)</span></li>
          <li><i class="fa fa-file"></i>[SubsPlease] Example - 02 (1080p) [BBBB].mkv <span class="file-size">(1.3 GiB)</span></li>
        </ul></li>
      </ul>
    </div>
    """

    assert {:ok, parsed} = Parser.torrent(html)
    assert parsed.title == "[SubsPlease] Example (01-02) [Batch]"
    assert parsed.magnet_uri =~ "urn:btih:acbd9ede5bb0356f24c413998175ba556280a423"

    assert parsed.files == [
             %{path: "[SubsPlease] Example - 01 (1080p) [AAAA].mkv", size: "1.2 GiB"},
             %{path: "[SubsPlease] Example - 02 (1080p) [BBBB].mkv", size: "1.3 GiB"}
           ]
  end
end
