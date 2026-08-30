defmodule AnimeData.Catalog.Actions.EnqueuePending do
  use Ash.Resource.Actions.Implementation

  @impl true
  def run(_input, _opts, _context), do: AnimeData.Catalog.MatchService.enqueue_pending()
end
