defmodule Histoire.SubsPlease.Actions.Latest do
  @moduledoc false

  use Ash.Resource.Actions.Implementation

  @impl true
  def run(_input, _opts, _context) do
    case Histoire.SubsPlease.SyncService.latest() do
      {:ok, _summary} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
