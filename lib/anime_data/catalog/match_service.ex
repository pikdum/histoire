defmodule AnimeData.Catalog.MatchService do
  @moduledoc false

  import Ash.Query

  alias AnimeData.Catalog.{Mapping, MatchDecision, Matcher, MatchJobs}
  alias AnimeData.SubsPlease.Show

  def run(mapping_id) do
    mapping = Mapping.get_by_id!(mapping_id)

    if mapping.tvdb_id do
      :ok
    else
      do_run(mapping)
    end
  end

  def enqueue_pending do
    results =
      Mapping
      |> filter(status == :pending and is_nil(tvdb_id))
      |> Ash.read!()
      |> Enum.with_index()
      |> Enum.map(fn {mapping, index} ->
        MatchJobs.enqueue(mapping.id, priority: 3, schedule_in: index * 5)
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, %{jobs: length(results)}}
      {:error, error} -> {:error, error}
    end
  end

  def apply_decision(mapping, %MatchDecision{} = decision) do
    attempted_at = DateTime.utc_now()
    attempts = mapping.attempts + 1
    threshold = Application.get_env(:anime_data, :automatic_match_confidence, 0.85)

    attributes =
      case decision do
        %{status: :matched, tvdb_id: tvdb_id, confidence: confidence}
        when is_integer(tvdb_id) and confidence >= threshold ->
          %{
            tvdb_id: tvdb_id,
            candidate_tvdb_id: nil,
            status: :matched,
            matched_at: attempted_at
          }

        %{status: status, tvdb_id: tvdb_id} when status in [:matched, :needs_review] ->
          %{
            tvdb_id: nil,
            candidate_tvdb_id: tvdb_id,
            status: :needs_review,
            matched_at: nil
          }

        %{status: :no_match} ->
          %{
            tvdb_id: nil,
            candidate_tvdb_id: nil,
            status: :no_match,
            matched_at: nil
          }
      end

    attributes =
      Map.merge(attributes, %{
        match_confidence: decision.confidence,
        match_reasoning: decision.reasoning,
        match_method: :llm,
        last_attempted_at: attempted_at,
        last_error: nil,
        attempts: attempts
      })

    with {:ok, updated} <- Mapping.record_result(mapping, attributes) do
      if updated.tvdb_id do
        _result = AnimeData.TVDB.Jobs.enqueue_series(updated.tvdb_id, priority: 0)
      end

      {:ok, updated}
    end
  end

  defp do_run(mapping) do
    show = Show.get_by_id!(mapping.subsplease_id, load: [:releases])

    release_dates =
      show.releases
      |> Enum.map(& &1.source_date)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    case invoke_matcher(show.name, show.synopsis, release_dates) do
      {:ok, decision} ->
        case apply_decision(mapping, decision) do
          {:ok, _mapping} -> :ok
          {:error, error} -> record_failure(mapping, error)
        end

      {:error, error} ->
        record_failure(mapping, error)
    end
  end

  defp invoke_matcher(name, synopsis, release_dates) do
    Matcher.match_tvdb(name, synopsis, release_dates)
  rescue
    error -> {:error, error}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp record_failure(mapping, error) do
    attributes = %{
      last_attempted_at: DateTime.utc_now(),
      last_error: inspect(error, limit: 20, printable_limit: 2_000),
      attempts: mapping.attempts + 1
    }

    _result = Mapping.record_failure(mapping, attributes)
    {:error, error}
  end
end
