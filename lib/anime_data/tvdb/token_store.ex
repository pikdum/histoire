defmodule AnimeData.TVDB.TokenStore do
  @moduledoc "Lazily obtains and caches the TVDB bearer token."

  use GenServer

  @refresh_after_ms :timer.hours(11)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def token do
    GenServer.call(__MODULE__, :token, 30_000)
  end

  def invalidate do
    GenServer.cast(__MODULE__, :invalidate)
  end

  @impl GenServer
  def init(_opts), do: {:ok, %{token: nil, refresh_timer: nil}}

  @impl GenServer
  def handle_call(:token, _from, %{token: token} = state) when is_binary(token) do
    {:reply, {:ok, token}, state}
  end

  def handle_call(:token, _from, state) do
    case login() do
      {:ok, token} -> {:reply, {:ok, token}, store_token(state, token)}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl GenServer
  def handle_cast(:invalidate, state), do: {:noreply, clear_token(state)}

  @impl GenServer
  def handle_info(:refresh, state) do
    case login() do
      {:ok, token} -> {:noreply, store_token(state, token)}
      {:error, _reason} -> {:noreply, clear_token(state)}
    end
  end

  defp login do
    with api_key when is_binary(api_key) and api_key != "" <-
           Application.get_env(:anime_data, :tvdb_api_key),
         {:ok, token} <- AnimeData.TVDB.Client.login(api_key) do
      {:ok, token}
    else
      nil -> {:error, :tvdb_api_key_not_configured}
      "" -> {:error, :tvdb_api_key_not_configured}
      {:error, reason} -> {:error, reason}
    end
  end

  defp store_token(state, token) do
    state = cancel_timer(state)

    %{
      state
      | token: token,
        refresh_timer: Process.send_after(self(), :refresh, @refresh_after_ms)
    }
  end

  defp clear_token(state) do
    state = cancel_timer(state)
    %{state | token: nil, refresh_timer: nil}
  end

  defp cancel_timer(%{refresh_timer: nil} = state), do: state

  defp cancel_timer(%{refresh_timer: timer} = state) do
    Process.cancel_timer(timer)
    state
  end
end
