defmodule AnimeData.SubsPlease.SchedulePlannerTest do
  use ExUnit.Case, async: true

  alias AnimeData.SubsPlease.SchedulePlanner

  test "schedules five minutes after the next UTC weekday/time" do
    entry = %{weekday: "Wednesday", scheduled_time: ~T[14:00:00]}
    now = ~U[2026-08-24 12:00:00Z]

    assert SchedulePlanner.seconds_until_release_check(entry, now) ==
             2 * 24 * 60 * 60 + 2 * 60 * 60 + 5 * 60
  end

  test "rolls an already elapsed slot forward one week" do
    entry = %{weekday: "Monday", scheduled_time: ~T[14:00:00]}
    now = ~U[2026-08-24 14:06:00Z]

    assert SchedulePlanner.seconds_until_release_check(entry, now) ==
             7 * 24 * 60 * 60 - 60
  end
end
