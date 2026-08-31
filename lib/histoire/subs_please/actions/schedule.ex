defmodule Histoire.SubsPlease.Actions.Schedule do
  @moduledoc false

  use Ash.Resource.Actions.Implementation

  @impl true
  def run(_input, _opts, _context) do
    case Histoire.SubsPlease.SyncService.schedule() do
      {:ok, _summary} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
