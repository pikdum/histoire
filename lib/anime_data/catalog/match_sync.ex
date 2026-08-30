defmodule AnimeData.Catalog.MatchSync do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.Catalog,
    extensions: [AshOban]

  oban do
    scheduled_actions do
      schedule :enqueue_pending_matches, "45 */6 * * *" do
        action :enqueue_pending
        queue :tvdb_match
        priority 3
        max_attempts 5
        tags ["catalog", "tvdb-match", "bootstrap"]
        worker_module_name AnimeData.Catalog.Workers.EnqueuePendingMatches
      end
    end
  end

  code_interface do
    define :enqueue_pending
  end

  actions do
    action :enqueue_pending do
      run AnimeData.Catalog.Actions.EnqueuePending
    end
  end
end
