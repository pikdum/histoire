defmodule AnimeData.SubsPlease.SyncService do
  @moduledoc false

  alias AnimeData.SubsPlease.{Client, Importer, Jobs, ScheduleEntry, SchedulePlanner, Show}

  @bulk_spacing_seconds 10

  def discover do
    with {:ok, index_entries} <- Client.fetch_index() do
      shows_by_slug = Show.list!() |> Map.new(&{&1.slug, &1})

      results =
        index_entries
        |> Enum.with_index()
        |> Enum.map(fn {%{slug: slug}, index} ->
          opts = [priority: 3, schedule_in: index * @bulk_spacing_seconds]

          case Map.get(shows_by_slug, slug) do
            nil -> Jobs.enqueue_show_page(slug, opts)
            show -> Jobs.enqueue_releases(show.id, opts)
          end
        end)

      summarize_jobs(results)
    end
  end

  def latest do
    with {:ok, latest_entries} <- Client.fetch_latest() do
      shows_by_slug = Show.list!() |> Map.new(&{&1.slug, &1})

      results =
        latest_entries
        |> Enum.uniq_by(& &1.slug)
        |> Enum.map(fn %{slug: slug} ->
          case Map.get(shows_by_slug, slug) do
            nil -> Jobs.enqueue_show_page(slug, priority: 0)
            show -> Jobs.enqueue_releases(show.id, priority: 0)
          end
        end)

      summarize_jobs(results)
    end
  end

  def schedule do
    with {:ok, entries} <- Client.fetch_schedule(),
         {:ok, count} <- Importer.schedule(entries) do
      jobs =
        ScheduleEntry.list!()
        |> Enum.reject(&is_nil(&1.show_id))
        |> Enum.map(fn entry ->
          Jobs.enqueue_releases(entry.show_id,
            priority: 0,
            schedule_in: SchedulePlanner.seconds_until_release_check(entry)
          )
        end)

      with {:ok, %{jobs: job_count}} <- summarize_jobs(jobs) do
        {:ok, %{schedule_entries: count, jobs: job_count}}
      end
    end
  end

  defp summarize_jobs(results) do
    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, %{jobs: length(results)}}
      {:error, error} -> {:error, error}
    end
  end
end
