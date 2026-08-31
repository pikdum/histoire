defmodule Histoire.Torrents.Magnet do
  @moduledoc "Canonicalizes BitTorrent info hashes without discarding magnet parameters."

  @base32_hash_length 32
  @hex_hash_length 40

  def canonicalize(uri) when is_binary(uri) do
    with "magnet:?" <> query <- uri,
         {:ok, params} <- decode_query(query),
         {:ok, params} <- canonicalize_xt(params) do
      {:ok, "magnet:?" <> encode_query(params)}
    else
      _reason -> {:error, :invalid_magnet_uri}
    end
  end

  def canonicalize(_uri), do: {:error, :invalid_magnet_uri}

  def canonicalize_or_original(uri) do
    case canonicalize(uri) do
      {:ok, canonical} -> canonical
      {:error, _reason} -> uri
    end
  end

  defp decode_query(query) do
    {:ok, Enum.to_list(URI.query_decoder(query))}
  rescue
    ArgumentError -> {:error, :invalid_query}
  end

  defp canonicalize_xt(params) do
    Enum.reduce_while(params, {:error, :missing_btih}, fn
      {"xt", "urn:btih:" <> hash}, _acc ->
        case canonical_hash(hash) do
          {:ok, canonical} ->
            updated = replace_first_xt(params, "urn:btih:" <> canonical)
            {:halt, {:ok, updated}}

          {:error, _reason} = error ->
            {:halt, error}
        end

      _param, acc ->
        {:cont, acc}
    end)
  end

  defp canonical_hash(hash) when byte_size(hash) == @base32_hash_length do
    case Base.decode32(hash, case: :mixed, padding: false) do
      {:ok, bytes} when byte_size(bytes) == 20 -> {:ok, Base.encode16(bytes, case: :lower)}
      _result -> {:error, :invalid_btih}
    end
  end

  defp canonical_hash(hash) when byte_size(hash) == @hex_hash_length do
    case Base.decode16(hash, case: :mixed) do
      {:ok, bytes} when byte_size(bytes) == 20 -> {:ok, String.downcase(hash)}
      _result -> {:error, :invalid_btih}
    end
  end

  defp canonical_hash(_hash), do: {:error, :invalid_btih}

  defp replace_first_xt(params, replacement) do
    {updated, _replaced?} =
      Enum.map_reduce(params, false, fn
        {"xt", "urn:btih:" <> _hash}, false -> {{"xt", replacement}, true}
        param, replaced? -> {param, replaced?}
      end)

    updated
  end

  defp encode_query(params) do
    Enum.map_join(params, "&", fn {key, value} ->
      encoded_value = URI.encode_www_form(value)

      encoded_value =
        if key == "xt", do: String.replace(encoded_value, "%3A", ":"), else: encoded_value

      URI.encode_www_form(key) <> "=" <> encoded_value
    end)
  end
end
