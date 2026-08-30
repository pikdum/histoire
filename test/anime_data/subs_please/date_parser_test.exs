defmodule AnimeData.SubsPlease.DateParserTest do
  use ExUnit.Case, async: true

  alias AnimeData.SubsPlease.DateParser

  test "parses source dates without losing the upstream value's century" do
    assert {:ok, ~D[2024-12-11]} = DateParser.source_date("12/11/24")
    assert {:ok, nil} = DateParser.source_date("New")
  end

  test "normalizes RFC 2822 release timestamps to UTC" do
    assert {:ok, ~U[2024-12-11 14:17:56Z]} =
             DateParser.released_at("Wed, 11 Dec 2024 19:47:56 +0530")
  end

  test "rejects malformed source values" do
    assert {:error, {:invalid_source_date, "later"}} = DateParser.source_date("later")
    assert {:error, {:invalid_release_date, "later"}} = DateParser.released_at("later")
  end
end
