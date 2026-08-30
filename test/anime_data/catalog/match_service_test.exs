defmodule AnimeData.Catalog.MatchServiceTest do
  use AnimeData.DataCase, async: true
  use Oban.Testing, repo: AnimeData.Repo

  alias AnimeData.Catalog.{Mapping, MatchDecision, MatchService}
  alias AnimeData.SubsPlease.Importer
  alias AnimeData.TVDB.Workers.Series

  setup do
    show_id = System.unique_integer([:positive])

    assert {:ok, _show} =
             Importer.show(%{
               id: show_id,
               slug: "show-#{show_id}",
               name: "Example Show",
               synopsis: "An example synopsis.",
               fetched_at: ~U[2026-08-30 00:00:00Z]
             })

    %{mapping: Mapping.get_by_subsplease_id!(show_id)}
  end

  test "accepts a high-confidence LLM result and queues its TVDB mirror", %{mapping: mapping} do
    decision =
      MatchDecision.new!(
        status: :matched,
        tvdb_id: 427_831,
        confidence: 0.96,
        reasoning: "The synopsis and 2024 broadcast dates agree."
      )

    assert {:ok, updated} = MatchService.apply_decision(mapping, decision)
    assert updated.status == :matched
    assert updated.tvdb_id == 427_831
    assert updated.match_method == :llm
    assert updated.attempts == 1
    assert_enqueued worker: Series, args: %{"tvdb_id" => 427_831}, priority: 0
  end

  test "keeps lower-confidence results as reviewable candidates", %{mapping: mapping} do
    decision =
      MatchDecision.new!(
        status: :matched,
        tvdb_id: 427_831,
        confidence: 0.72,
        reasoning: "The title agrees but the date evidence is incomplete."
      )

    assert {:ok, review} = MatchService.apply_decision(mapping, decision)
    assert review.status == :needs_review
    assert review.tvdb_id == nil
    assert review.candidate_tvdb_id == 427_831

    assert {:ok, accepted} = Mapping.accept_candidate(review)
    assert accepted.status == :matched
    assert accepted.tvdb_id == 427_831
    assert accepted.match_method == :manual
    assert_enqueued worker: Series, args: %{"tvdb_id" => 427_831}, priority: 0
  end

  test "records an explicit no-match without inventing an ID", %{mapping: mapping} do
    decision =
      MatchDecision.new!(
        status: :no_match,
        tvdb_id: nil,
        confidence: 0.91,
        reasoning: "Multiple title variants produced no corresponding TVDB series."
      )

    assert {:ok, updated} = MatchService.apply_decision(mapping, decision)
    assert updated.status == :no_match
    assert updated.tvdb_id == nil
    assert updated.candidate_tvdb_id == nil
  end
end
