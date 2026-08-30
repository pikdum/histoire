defmodule AnimeData.SubsPlease.JobsTest do
  use AnimeData.DataCase, async: true
  use Oban.Testing, repo: AnimeData.Repo

  alias AnimeData.SubsPlease.Jobs
  alias AnimeData.SubsPlease.Workers.ShowPage

  test "a hot poll promotes an already scheduled bulk job" do
    assert {:ok, low_job} =
             Jobs.enqueue_show_page("acro-trip", priority: 3, schedule_in: 3_600)

    assert low_job.priority == 3
    assert low_job.state == "scheduled"

    assert {:ok, hot_job} = Jobs.enqueue_show_page("acro-trip", priority: 0)
    assert hot_job.id == low_job.id
    assert hot_job.conflict?
    assert hot_job.priority == 0
    assert hot_job.state == "scheduled"
    assert DateTime.diff(hot_job.scheduled_at, DateTime.utc_now(), :second) <= 1

    assert_enqueued worker: ShowPage, args: %{"slug" => "acro-trip"}, priority: 0
  end

  test "bulk discovery cannot demote or postpone an existing hot job" do
    assert {:ok, hot_job} =
             Jobs.enqueue_show_page("future-show", priority: 0, schedule_in: 600)

    assert {:ok, conflict} =
             Jobs.enqueue_show_page("future-show", priority: 3, schedule_in: 3_600)

    assert conflict.id == hot_job.id
    assert conflict.conflict?
    assert conflict.priority == 0
    assert conflict.scheduled_at == hot_job.scheduled_at
  end
end
