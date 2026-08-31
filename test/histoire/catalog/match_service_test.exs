defmodule Histoire.Catalog.MatchServiceTest do
  use Histoire.DataCase, async: true
  use Oban.Testing, repo: Histoire.Repo

  alias Histoire.Catalog.{Mapping, MatchDecision, MatchService}
  alias Histoire.SubsPlease.Importer
  alias Histoire.TVDB.Workers.{Movie, Series}

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

    assert {:ok, 0} = Importer.releases(show_id, [])

    %{mapping: Mapping.get_by_subsplease_id!(show_id)}
  end

  test "accepts a high-confidence LLM result and queues its TVDB mirror", %{mapping: mapping} do
    decision =
      MatchDecision.new!(
        status: :matched,
        tvdb_id: 427_831,
        tvdb_type: :series,
        confidence: 0.96,
        reasoning: "The synopsis and 2024 broadcast dates agree."
      )

    assert {:ok, updated} = MatchService.apply_decision(mapping, decision)
    assert updated.status == :matched
    assert updated.tvdb_id == 427_831
    assert updated.tvdb_type == :series
    assert updated.match_method == :llm
    assert updated.attempts == 1
    assert_enqueued worker: Series, args: %{"tvdb_id" => 427_831}, priority: 0
  end

  test "keeps lower-confidence results as reviewable candidates", %{mapping: mapping} do
    decision =
      MatchDecision.new!(
        status: :matched,
        tvdb_id: 427_831,
        tvdb_type: :series,
        confidence: 0.72,
        reasoning: "The title agrees but the date evidence is incomplete."
      )

    assert {:ok, review} = MatchService.apply_decision(mapping, decision)
    assert review.status == :needs_review
    assert review.tvdb_id == nil
    assert review.candidate_tvdb_id == 427_831
    assert review.candidate_tvdb_type == :series

    assert {:ok, accepted} = Mapping.accept_candidate(review)
    assert accepted.status == :matched
    assert accepted.tvdb_id == 427_831
    assert accepted.tvdb_type == :series
    assert accepted.match_method == :manual
    assert_enqueued worker: Series, args: %{"tvdb_id" => 427_831}, priority: 0
  end

  test "allows multiple SubsPlease seasons to map to one TVDB series", %{mapping: mapping} do
    decision =
      MatchDecision.new!(
        status: :matched,
        tvdb_id: 412_843,
        tvdb_type: :series,
        confidence: 0.97,
        reasoning: "TVDB stores both seasons under one series."
      )

    assert {:ok, first} = MatchService.apply_decision(mapping, decision)

    second_show_id = System.unique_integer([:positive])

    assert {:ok, _show} =
             Importer.show(%{
               id: second_show_id,
               slug: "second-season-#{second_show_id}",
               name: "Example Show S2",
               synopsis: "The second season.",
               fetched_at: ~U[2026-08-30 00:00:00Z]
             })

    assert {:ok, 0} = Importer.releases(second_show_id, [])

    second_mapping = Mapping.get_by_subsplease_id!(second_show_id)
    assert {:ok, second} = MatchService.apply_decision(second_mapping, decision)
    assert first.tvdb_id == second.tvdb_id
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

  test "accepts a movie result and queues the movie mirror", %{mapping: mapping} do
    decision =
      MatchDecision.new!(
        status: :matched,
        tvdb_id: 199_463,
        tvdb_type: :movie,
        confidence: 0.98,
        reasoning: "The Japanese and English titles identify Bakuten!! Movie."
      )

    assert {:ok, updated} = MatchService.apply_decision(mapping, decision)
    assert updated.tvdb_type == :movie
    assert_enqueued worker: Movie, args: %{"tvdb_id" => 199_463}, priority: 0
  end

  test "rejects a candidate without an entity type", %{mapping: mapping} do
    decision =
      MatchDecision.new!(
        status: :matched,
        tvdb_id: 199_463,
        confidence: 0.98,
        reasoning: "An ID without its TVDB entity type is ambiguous."
      )

    assert {:error, :invalid_match_decision} = MatchService.apply_decision(mapping, decision)
    assert Mapping.get_by_id!(mapping.id).status == :pending
  end

  test "requires both an ID and entity type for a manual match", %{mapping: mapping} do
    assert {:error, _error} = Mapping.set_tvdb(mapping, %{tvdb_id: 199_463})
    assert {:error, _error} = Mapping.set_tvdb(mapping, %{tvdb_type: :movie})
  end
end
