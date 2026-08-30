defmodule AnimeData.Catalog.MatchJobs do
  @moduledoc false

  alias AnimeData.Catalog.Workers.MatchTVDB

  def enqueue(mapping_id, opts \\ []) do
    priority = Keyword.get(opts, :priority, 3)
    schedule_in = Keyword.get(opts, :schedule_in, 0)

    job_opts = [priority: priority, schedule_in: schedule_in]
    job_opts = if priority == 3, do: Keyword.put(job_opts, :replace, []), else: job_opts

    %{"mapping_id" => mapping_id}
    |> MatchTVDB.new(job_opts)
    |> Oban.insert()
  end
end
