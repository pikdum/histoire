defmodule Histoire.Catalog.MatcherTest do
  use ExUnit.Case, async: true

  alias Histoire.Catalog.SubsPleaseTVDBShowMatch, as: Mapping

  test "exposes read-only TVDB and constrained web research tools" do
    tools = AshAi.Info.tools(Histoire.TVDB)

    assert Enum.map(tools, & &1.name) == [
             :search_tvdb_titles,
             :search_web_for_tvdb_title,
             :get_tvdb_series,
             :get_tvdb_movie,
             :get_tvdb_series_by_slug
           ]

    assert Enum.all?(tools, &(&1.resource == Histoire.TVDB.Lookup))
  end

  test "schedules pending mappings through a dedicated AshOban trigger" do
    trigger = AshOban.Info.oban_trigger(Mapping, :match_tvdb)

    assert trigger.action == :run_tvdb_match
    assert trigger.on_error == :record_match_failure
    assert trigger.queue == :tvdb_match
    assert trigger.scheduler_queue == :schedulers
    assert trigger.scheduler_cron == "* * * * *"
    assert trigger.worker_module_name == Histoire.Catalog.Workers.MatchTVDB
    assert trigger.scheduler_module_name == Histoire.Catalog.Schedulers.MatchTVDB
  end
end
