defmodule AnimeData.TVDB.Actions.RefreshAll do
  use Ash.Resource.Actions.Implementation

  @impl true
  def run(_input, _opts, _context) do
    case AnimeData.TVDB.SyncService.refresh_all() do
      {:ok, _summary} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
