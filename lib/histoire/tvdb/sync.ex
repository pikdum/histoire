defmodule Histoire.TVDB.Sync do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.TVDB,
    extensions: [AshOban]

  oban do
    scheduled_actions do
      schedule :daily_refresh, "30 5 * * *" do
        action :refresh_all
        queue :schedulers
        priority 3
        max_attempts 5
        tags ["tvdb", "refresh-all"]
        worker_module_name Histoire.TVDB.Workers.DailyRefresh
      end
    end
  end

  code_interface do
    define :refresh_all
  end

  actions do
    action :refresh_all do
      run Histoire.TVDB.Actions.RefreshAll
    end
  end
end
