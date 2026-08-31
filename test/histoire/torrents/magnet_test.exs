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

  test "shapes a SubsPlease magnet exactly like Nyaa" do
    magnet =
      "magnet:?xt=urn:btih:VS6Z5XS3WA2W6JGECOMYC5N2KVRIBJBD" <>
        "&dn=Acro%20Trip&xl=1234" <>
        "&tr=http%3A%2F%2Fnyaa.tracker.wf%3A7777%2Fannounce" <>
        "&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce" <>
        "&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce" <>
        "&tr=udp%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce" <>
        "&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce" <>
        "&tr=udp%3A%2F%2Fextra.invalid%3A80%2Fannounce"

    expected =
      "magnet:?xt=urn:btih:acbd9ede5bb0356f24c413998175ba556280a423" <>
        "&dn=Acro+Trip" <>
        "&tr=http%3A%2F%2Fnyaa.tracker.wf%3A7777%2Fannounce" <>
        "&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce" <>
        "&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce" <>
        "&tr=udp%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce" <>
        "&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce"

    assert {:ok, ^expected} = Magnet.canonicalize_for_nyaa(magnet)
  end

  test "rejects malformed magnets" do
    assert {:error, :invalid_magnet_uri} =
             Magnet.canonicalize("https://example.test/file.torrent")

    assert {:error, :invalid_magnet_uri} = Magnet.canonicalize("magnet:?xt=urn:btih:nope")
  end
end
