defmodule AnimeData.SubsPlease.DateParser do
  @moduledoc false

  @months %{
    "Jan" => 1,
    "Feb" => 2,
    "Mar" => 3,
    "Apr" => 4,
    "May" => 5,
    "Jun" => 6,
    "Jul" => 7,
    "Aug" => 8,
    "Sep" => 9,
    "Oct" => 10,
    "Nov" => 11,
    "Dec" => 12
  }

  def source_date("New"), do: {:ok, nil}
  def source_date(nil), do: {:ok, nil}

  def source_date(value) when is_binary(value) do
    case String.split(value, "/") do
      [month, day, year] ->
        with {month, ""} <- Integer.parse(month),
             {day, ""} <- Integer.parse(day),
             {year, ""} <- Integer.parse(year) do
          Date.new(2000 + year, month, day)
        else
          _ -> {:error, {:invalid_source_date, value}}
        end

      _ ->
        {:error, {:invalid_source_date, value}}
    end
  end

  def released_at(nil), do: {:ok, nil}

  def released_at(value) when is_binary(value) do
    regex =
      ~r/^(?:[A-Za-z]{3},\s+)?(\d{2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s+([+-])(\d{2})(\d{2})$/

    with [_, day, month_name, year, hour, minute, second, sign, offset_hour, offset_minute] <-
           Regex.run(regex, value),
         month when is_integer(month) <- Map.get(@months, month_name),
         integers <-
           Enum.map(
             [year, day, hour, minute, second, offset_hour, offset_minute],
             &String.to_integer/1
           ),
         [year, day, hour, minute, second, offset_hour, offset_minute] <- integers,
         {:ok, date} <- Date.new(year, month, day),
         {:ok, time} <- Time.new(hour, minute, second),
         {:ok, datetime} <- DateTime.new(date, time, "Etc/UTC") do
      offset = (offset_hour * 60 + offset_minute) * 60
      offset = if sign == "+", do: offset, else: -offset
      {:ok, DateTime.add(datetime, -offset, :second)}
    else
      _ -> {:error, {:invalid_release_date, value}}
    end
  end

  def scheduled_time(value) when is_binary(value) do
    case Time.from_iso8601(value <> ":00") do
      {:ok, time} -> {:ok, time}
      {:error, _reason} -> {:error, {:invalid_scheduled_time, value}}
    end
  end
end
