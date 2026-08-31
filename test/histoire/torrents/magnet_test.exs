defmodule Histoire.Torrents.MagnetTest do
  use ExUnit.Case, async: true

  alias Histoire.Torrents.Magnet

  test "canonicalizes base32 BTIH values to lowercase hex and preserves trackers" do
    magnet =
      "magnet:?xt=urn:btih:VS6Z5XS3WA2W6JGECOMYC5N2KVRIBJBD" <>
        "&dn=Acro%20Trip&tr=udp%3A%2F%2Ftracker.one&tr=udp%3A%2F%2Ftracker.two"

    assert {:ok, canonical} = Magnet.canonicalize(magnet)

    assert canonical =~ "xt=urn:btih:acbd9ede5bb0356f24c413998175ba556280a423"
    assert canonical =~ "dn=Acro+Trip"
    assert length(Regex.scan(~r/(?:^|&)tr=/, canonical)) == 2
  end

  test "normalizes a hex BTIH without changing other query parameters" do
    magnet = "magnet:?xt=urn:btih:ACBD9EDE5BB0356F24C413998175BA556280A423&tr=udp%3A%2F%2Ftracker"

    assert {:ok, canonical} = Magnet.canonicalize(magnet)
    assert canonical =~ "urn:btih:acbd9ede5bb0356f24c413998175ba556280a423"
    assert canonical =~ "tr=udp%3A%2F%2Ftracker"
  end

  test "rejects malformed magnets" do
    assert {:error, :invalid_magnet_uri} =
             Magnet.canonicalize("https://example.test/file.torrent")

    assert {:error, :invalid_magnet_uri} = Magnet.canonicalize("magnet:?xt=urn:btih:nope")
  end
end
