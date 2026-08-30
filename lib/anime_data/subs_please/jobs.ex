defmodule AnimeData.SubsPlease.Jobs do
  @moduledoc false

  alias AnimeData.SubsPlease.Workers.{Release, ShowPage}

  def enqueue_show_page(slug, opts \\ []) do
    insert(ShowPage, %{"slug" => slug}, opts)
  end

  def enqueue_releases(show_id, opts \\ []) do
    insert(Release, %{"show_id" => show_id}, opts)
  end

  defp insert(worker, args, opts) do
    priority = Keyword.get(opts, :priority, 3)
    schedule_in = Keyword.get(opts, :schedule_in, 0)

    # Keep `schedule_in` present even for immediate work so Oban can replace a
    # bulk job's future `scheduled_at` when a hot poll finds the same args.
    job_opts = [priority: priority, schedule_in: schedule_in]

    # Bulk discovery may encounter a job that schedule/latest polling already
    # made hot. In that direction the existing job must win unchanged.
    job_opts = if priority == 3, do: Keyword.put(job_opts, :replace, []), else: job_opts

    args
    |> worker.new(job_opts)
    |> Oban.insert()
  end
end
