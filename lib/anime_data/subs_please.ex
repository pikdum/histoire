defmodule AnimeData.SubsPlease do
  use Ash.Domain, otp_app: :anime_data, extensions: [AshGraphql.Domain, AshAdmin.Domain]

  admin do
    show? true
  end

  graphql do
    authorize? false

    queries do
      get AnimeData.SubsPlease.Show, :show, :read
      list AnimeData.SubsPlease.Show, :shows, :read
      get AnimeData.SubsPlease.Release, :release, :read
      list AnimeData.SubsPlease.Release, :releases, :read
      list AnimeData.SubsPlease.ScheduleEntry, :schedule_entries, :read
    end
  end

  resources do
    resource AnimeData.SubsPlease.Show
    resource AnimeData.SubsPlease.Release
    resource AnimeData.SubsPlease.Download
    resource AnimeData.SubsPlease.ScheduleEntry
    resource AnimeData.SubsPlease.Sync
  end
end
