defmodule AnimeData.Catalog.Changes.RunTVDBMatch do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, mapping ->
      case AnimeData.Catalog.MatchService.run(mapping.id) do
        :ok -> {:ok, AnimeData.Catalog.Mapping.get_by_id!(mapping.id)}
        {:error, error} -> {:error, error}
      end
    end)
  end
end
