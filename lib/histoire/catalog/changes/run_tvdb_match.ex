defmodule Histoire.Catalog.Changes.RunTVDBMatch do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, mapping ->
      case Histoire.Catalog.MatchService.run(mapping.id) do
        :ok -> {:ok, Histoire.Catalog.Mapping.get_by_id!(mapping.id)}
        {:error, error} -> {:error, error}
      end
    end)
  end
end
