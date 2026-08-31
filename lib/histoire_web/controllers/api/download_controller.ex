defmodule HistoireWeb.Api.DownloadController do
  use HistoireWeb, :controller

  alias Histoire.Catalog.ReadModel
  alias Histoire.Nyaa.Enrichment
  alias Histoire.SubsPlease.Download

  require Logger

  def files(conn, %{"id" => id}) do
    with {:ok, download} <-
           Download.get_by_id(id, load: [:release, :nyaa_download_override]),
         :ok <- ensure_batch(download),
         {:ok, torrent} <- Enrichment.get_or_fetch(Download.nyaa_target(download)) do
      json(conn, %{data: ReadModel.download_files(torrent)})
    else
      {:error, %Ash.Error.Query.NotFound{}} ->
        render_error(conn, :not_found, "download not found")

      {:error, :not_a_batch} ->
        render_error(conn, :unprocessable_entity, "not a batch download")

      {:error, :invalid_nyaa_url} ->
        render_error(conn, :unprocessable_entity, "invalid Nyaa URL")

      {:error, {:http_status, status, _path}} when status in [404, 410] ->
        render_error(conn, :not_found, "Nyaa torrent not found")

      {:error, reason} ->
        Logger.error("Nyaa enrichment failed: #{inspect(reason)}")
        render_error(conn, :bad_gateway, "Nyaa enrichment failed")
    end
  end

  defp ensure_batch(%{release: %{kind: :batch}}), do: :ok
  defp ensure_batch(_download), do: {:error, :not_a_batch}

  defp render_error(conn, status, message) do
    conn
    |> put_status(status)
    |> json(%{error: message})
  end
end
