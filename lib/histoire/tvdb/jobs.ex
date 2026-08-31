defmodule Histoire.TVDB.Jobs do
  @moduledoc false

  alias Histoire.TVDB.Workers.{Movie, Series}

  def enqueue(:series, tvdb_id, opts), do: enqueue_series(tvdb_id, opts)
  def enqueue(:movie, tvdb_id, opts), do: enqueue_movie(tvdb_id, opts)

  def enqueue_series(tvdb_id, opts \\ []) do
    insert(Series, tvdb_id, opts)
  end

  def enqueue_movie(tvdb_id, opts \\ []) do
    insert(Movie, tvdb_id, opts)
  end

  defp insert(worker, tvdb_id, opts) do
    priority = Keyword.get(opts, :priority, 3)
    schedule_in = Keyword.get(opts, :schedule_in, 0)

    job_opts = [priority: priority, schedule_in: schedule_in]
    job_opts = if priority == 3, do: Keyword.put(job_opts, :replace, []), else: job_opts

    %{"tvdb_id" => tvdb_id}
    |> worker.new(job_opts)
    |> Oban.insert()
  end
end
