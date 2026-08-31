defmodule Histoire.Catalog.Changes.ValidateNyaaTorrent do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      nyaa_id = Ash.Changeset.get_attribute(changeset, :nyaa_id)

      case Histoire.Nyaa.Enrichment.get_or_fetch(nyaa_id) do
        {:ok, _torrent} ->
          changeset

        {:error, reason} ->
          Ash.Changeset.add_error(changeset,
            field: :nyaa_id,
            message: "could not fetch Nyaa torrent: #{inspect(reason)}"
          )
      end
    end)
  end
end
