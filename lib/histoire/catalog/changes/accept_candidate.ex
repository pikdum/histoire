defmodule Histoire.Catalog.Changes.AcceptCandidate do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.before_action(fn changeset ->
      case {changeset.data.candidate_tvdb_id, changeset.data.candidate_tvdb_type} do
        {nil, _type} ->
          Ash.Changeset.add_error(changeset, field: :candidate_tvdb_id, message: "is not set")

        {_tvdb_id, nil} ->
          Ash.Changeset.add_error(changeset,
            field: :candidate_tvdb_type,
            message: "is not set"
          )

        {tvdb_id, tvdb_type} ->
          changeset
          |> Ash.Changeset.force_change_attribute(:tvdb_id, tvdb_id)
          |> Ash.Changeset.force_change_attribute(:tvdb_type, tvdb_type)
          |> Ash.Changeset.force_change_attribute(:status, :matched)
          |> Ash.Changeset.force_change_attribute(:candidate_tvdb_id, nil)
          |> Ash.Changeset.force_change_attribute(:candidate_tvdb_type, nil)
          |> Ash.Changeset.force_change_attribute(:match_method, :manual)
          |> Ash.Changeset.force_change_attribute(:matched_at, DateTime.utc_now())
          |> Ash.Changeset.force_change_attribute(:last_error, nil)
      end
    end)
    |> Ash.Changeset.after_action(fn _changeset, mapping ->
      _result = Histoire.TVDB.Jobs.enqueue(mapping.tvdb_type, mapping.tvdb_id, priority: 0)
      {:ok, mapping}
    end)
  end
end
