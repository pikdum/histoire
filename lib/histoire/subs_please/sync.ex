defmodule Histoire.SubsPlease.Sync do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.SubsPlease,
    extensions: [AshOban]

  oban do
    scheduled_actions do
      schedule :daily_discovery, "0 4 * * *" do
        action :discover
        queue :subsplease_poll
        priority 1
        max_attempts 5
        tags ["subsplease", "discovery"]
        worker_module_name Histoire.SubsPlease.Workers.DailyDiscovery
      end

      schedule :latest_poll, "*/30 * * * *" do
        action :latest
        queue :subsplease_poll
        priority 0
        max_attempts 5
        tags ["subsplease", "latest"]
        worker_module_name Histoire.SubsPlease.Workers.LatestPoll
      end

      schedule :schedule_poll, "15 */6 * * *" do
        action :schedule
        queue :subsplease_poll
        priority 0
        max_attempts 5
        tags ["subsplease", "schedule"]
        worker_module_name Histoire.SubsPlease.Workers.SchedulePoll
      end
    end
  end

  code_interface do
    define :discover
    define :latest
    define :schedule
  end

  actions do
    action :discover do
      run Histoire.SubsPlease.Actions.Discover
    end

    action :latest do
      run Histoire.SubsPlease.Actions.Latest
    end

    action :schedule do
      run Histoire.SubsPlease.Actions.Schedule
    end
  end
end
