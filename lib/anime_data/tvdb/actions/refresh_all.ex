defmodule AnimeData.TVDB.Actions.RefreshAll do
  use Ash.Resource.Actions.Implementation

  @impl true
  def run(_input, _opts, _context), do: AnimeData.TVDB.SyncService.refresh_all()
end
