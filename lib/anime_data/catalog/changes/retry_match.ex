defmodule AnimeData.Catalog.Changes.RetryMatch do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.before_action(fn changeset ->
      changeset
      |> Ash.Changeset.force_change_attribute(:tvdb_id, nil)
      |> Ash.Changeset.force_change_attribute(:candidate_tvdb_id, nil)
      |> Ash.Changeset.force_change_attribute(:status, :pending)
      |> Ash.Changeset.force_change_attribute(:match_confidence, nil)
      |> Ash.Changeset.force_change_attribute(:match_reasoning, nil)
      |> Ash.Changeset.force_change_attribute(:match_method, nil)
      |> Ash.Changeset.force_change_attribute(:matched_at, nil)
      |> Ash.Changeset.force_change_attribute(:last_error, nil)
    end)
    |> Ash.Changeset.after_action(fn _changeset, mapping ->
      _job = AshOban.run_trigger(mapping, :match_tvdb, priority: 0)
      {:ok, mapping}
    end)
  end
end
