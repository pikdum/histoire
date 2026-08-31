defmodule Histoire.SubsPlease do
  use Ash.Domain, otp_app: :histoire, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Histoire.SubsPlease.Show
    resource Histoire.SubsPlease.Release
    resource Histoire.SubsPlease.Download
    resource Histoire.SubsPlease.ScheduleEntry
    resource Histoire.SubsPlease.Sync
  end
end
