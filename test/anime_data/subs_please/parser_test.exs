defmodule AnimeData.SubsPlease.ParserTest do
  use ExUnit.Case, async: true

  alias AnimeData.SubsPlease.Parser

  test "extracts and de-duplicates show slugs" do
    html = """
    <a href="/shows/acro-trip/" title="Acro Trip">one</a>
    <a href="/shows/acro-trip/" title="Acro Trip">duplicate</a>
    <a href="/shows/another-show/">Another Show</a>
    """

    assert Parser.index(html) == [
             %{name: "Acro Trip", slug: "acro-trip"},
             %{name: "Another Show", slug: "another-show"}
           ]
  end

  test "extracts a show page and normalizes its image URL" do
    html = """
    <h1 class="entry-title">Acro Trip</h1>
    <div class="series-syn"><p>A magical girl comedy.</p></div>
    <div id="show-release-table" sid="824"></div>
    <div id="secondary"><img class="img-responsive" src="/images/acro.jpg"></div>
    """

    assert {:ok, show} = Parser.show_page(html, "acro-trip")
    assert show.id == 824
    assert show.name == "Acro Trip"
    assert show.synopsis == "A magical girl comedy."
    assert show.image_url == "https://subsplease.org/images/acro.jpg"
  end

  test "generalizes episode and batch API rows as releases" do
    payload = %{
      "episode" => %{
        "Acro Trip - 12" => %{"episode" => "12", "downloads" => []}
      },
      "batch" => %{
        "Acro Trip - 01-12 (Batch)" => %{"episode" => "1-12", "downloads" => []}
      }
    }

    assert {:ok, releases} = Parser.releases(payload)

    assert [
             %{kind: :episode, name: "Acro Trip - 12"},
             %{kind: :batch, name: "Acro Trip - 01-12 (Batch)"}
           ] = Enum.map(releases, &Map.take(&1, [:kind, :name]))
  end

  test "distinguishes no releases from an invalid response" do
    assert {:ok, []} = Parser.releases(%{"episode" => [], "batch" => []})
    assert {:error, :invalid_releases_payload} = Parser.releases(%{})

    assert {:error, :invalid_releases_payload} =
             Parser.releases(%{"episode" => nil, "batch" => []})
  end

  test "distinguishes an empty schedule from an invalid response" do
    assert {:ok, []} = Parser.schedule(%{"schedule" => %{}})
    assert {:error, :invalid_schedule_payload} = Parser.schedule(%{})

    assert {:error, :invalid_schedule_payload} =
             Parser.schedule(%{"schedule" => %{"Monday" => nil}})
  end
end
