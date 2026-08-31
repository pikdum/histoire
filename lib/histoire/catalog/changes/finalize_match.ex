defmodule Histoire.Catalog.Changes.FinalizeMatch do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.before_action(fn changeset ->
      changeset
      |> Ash.Changeset.force_change_attribute(:status, :matched)
      |> Ash.Changeset.force_change_attribute(:candidate_tvdb_id, nil)
      |> Ash.Changeset.force_change_attribute(:candidate_tvdb_type, nil)
      |> Ash.Changeset.force_change_attribute(:match_method, :manual)
      |> Ash.Changeset.force_change_attribute(:matched_at, DateTime.utc_now())
      |> Ash.Changeset.force_change_attribute(:last_error, nil)
    end)
    |> Ash.Changeset.after_action(fn _changeset, mapping ->
      _result = Histoire.TVDB.Jobs.enqueue(mapping.tvdb_type, mapping.tvdb_id, priority: 0)
      {:ok, mapping}
    end)
  end
end
