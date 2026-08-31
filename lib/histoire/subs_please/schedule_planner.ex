defmodule Histoire.SubsPlease.SchedulePlanner do
  @moduledoc false

  @release_lag_seconds 5 * 60
  @week_seconds 7 * 24 * 60 * 60
  @weekdays %{
    "Monday" => 1,
    "Tuesday" => 2,
    "Wednesday" => 3,
    "Thursday" => 4,
    "Friday" => 5,
    "Saturday" => 6,
    "Sunday" => 7
  }

  def seconds_until_release_check(entry, now \\ DateTime.utc_now()) do
    weekday = Map.fetch!(@weekdays, entry.weekday)
    today = DateTime.to_date(now)
    days_ahead = Integer.mod(weekday - Date.day_of_week(today), 7)
    date = Date.add(today, days_ahead)
    scheduled_at = DateTime.new!(date, entry.scheduled_time, "Etc/UTC")
    release_check_at = DateTime.add(scheduled_at, @release_lag_seconds, :second)

    release_check_at =
      if DateTime.compare(release_check_at, now) == :gt do
        release_check_at
      else
        DateTime.add(release_check_at, @week_seconds, :second)
      end

    DateTime.diff(release_check_at, now, :second)
  end
end
