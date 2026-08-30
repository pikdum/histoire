defmodule AnimeData.Catalog.Changes.RecordMatchFailure do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, context) do
    error = Ash.Changeset.get_argument(changeset, :error)

    attempts =
      case context do
        %{ash_oban: %{job: %{attempt: attempt}}} -> attempt
        _context -> 1
      end

    changeset
    |> Ash.Changeset.force_change_attribute(:status, :failed)
    |> Ash.Changeset.force_change_attribute(:last_attempted_at, DateTime.utc_now())
    |> Ash.Changeset.force_change_attribute(
      :last_error,
      inspect(error, limit: 20, printable_limit: 2_000)
    )
    |> Ash.Changeset.force_change_attribute(:attempts, changeset.data.attempts + attempts)
  end
end
