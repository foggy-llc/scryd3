defmodule ScryD3.V2 do
  @moduledoc """
  Basic ID3v2 tag parsing.
  """
  require Logger
  use Bitwise
  alias ScryD3.V2.{ApicFrame, FrameHeaderFlags, HeaderFlags}

  @doc """
  Read the main ID3 header from the file. Extended header is not read nor allowed.

  Returns `version`, `flags` and `size` in bytes, as a Map.

  `version` is a `{major, minor}` tuple.
  `flags` is a `HeaderFlags` struct, see definition. Flags are only read, not recognized nor honored.
  """
  @spec header(binary) :: map
  def header(filecontents) do
    <<"ID3", version::binary-size(2), flags::integer-8, size::binary-size(4), _::binary>> =
      filecontents

    <<version_major, version_minor>> = version
    flags = read_flags(flags)

    if flags.extended_header do
      raise "This tag has an extended header. Extended header is not supported."
    end

    header = %{
      version: {version_major, version_minor},
      flags: flags,
      size: unpacked_size(size)
    }

    header
  end

  def read_flags(byte) do
    HeaderFlags.read(byte)
  end

  def unpacked_size(quadbyte) do
    <<byte1, byte2, byte3, byte4>> = quadbyte
    byte4 + (byte3 <<< 7) + (byte2 <<< 14) + (byte1 <<< 21)
  end

  @doc """
  Read all ID3 frames from the file.

  Returns a Map of 4-character frame ID to frame content. For example:

      %{
        "TIT2" => "Anesthetize"
        "TPE1" => "Porcupine Tree"
        "TALB" => "Fear of a Blank Planet"
        ...
      }
  """
  @spec frames(binary) :: map
  def frames(filecontent) do
    h = header(filecontent)
    header_size = h.size
    <<_header::binary-size(10), framedata::binary-size(header_size), _::binary>> = filecontent

    _read_frames(h, :binary.copy(framedata))
  end

  # Handle padding bytes at the end of the tag
  defp _read_frames(_, <<0, _::binary>>) do
    %{}
  end

  # Extra base case for files lacking pattern that matches the above
  defp _read_frames(_, <<>>) do
    %{}
  end

  defp _read_frames(header, framedata) do
    <<frameheader::binary-size(10), rest::binary>> = framedata
    <<key::binary-size(4), size::binary-size(4), flags::binary-size(2)>> = frameheader

    flags = FrameHeaderFlags.read(flags)

    pld_size =
      case header.version do
        {3, _} ->
          <<s::integer-32>> = size
          s

        {4, _} ->
          unpacked_size(size)

        {v, _} ->
          raise "ScryD3.#{v} not supported"
      end

    <<payload::binary-size(pld_size), rest::binary>> = rest

    # TODO handle more flags
    payload =
      if flags.unsynchronisation do
        p =
          if flags.data_length_indicator do
            <<_size::integer-32, p::binary>> = payload
            p
          else
            payload
          end

        strip_zero_bytes(p)
      else
        payload
      end

    key
    |> read_payload(payload)
    |> build_frame(key)
    |> Map.merge(_read_frames(header, rest))
  end

  def build_frame(_v, _k, _acc \\ %{})

  def build_frame(kv_pairs, key, _) when is_list(kv_pairs) do
    Enum.reduce(kv_pairs, %{}, fn values, acc ->
      build_frame(values, key, acc)
    end)
  end

  def build_frame({description, value}, key, acc) when is_map(value) do
    {key, value} = {key <> ":" <> description, value}
    Map.put(acc, key, value)
  end

  def build_frame({description, value}, key, acc) when is_map(acc) do
    {key, value} = {key <> ":" <> description, strip_zero_bytes(value)}
    Map.put(acc, key, :binary.copy(value))
  end

  def build_frame(value, key, _) do
    {key, value} = {key, strip_zero_bytes(value)}
    Map.put(%{}, key, :binary.copy(value))
  end

  def read_payload(key, payload) do
    <<_encoding::integer-8, _rest::binary>> = payload

    # Special case nonsense goes here
    case key do
      "WXXX" -> read_user_url(payload)
      "TXXX" -> read_user_text(payload)
      "IPLS" -> read_involved_people_list(payload, [])
      "COMM" -> read_comments(payload)
      "APIC" -> ApicFrame.read(payload)
      _ -> read_standard_payload(payload)
    end
  end

  defp read_comments(<<encoding::integer-8, language::binary-size(3), payload::binary>>) do
    {language, read_standard_payload(encoding, payload)}
  end

  defp read_standard_payload(encoding, payload) do
    # TODO Handle optional 3-byte language prefix
    case encoding do
      0 -> payload
      1 -> read_utf16(payload)
      2 -> raise "I don't support utf16 without a bom"
      3 -> payload
      _ -> payload
    end
  end

  defp read_standard_payload(<<encoding::integer-8, payload::binary>>) do
    read_standard_payload(encoding, payload)
  end

  def read_user_url(payload) do
    # TODO bubble up description somehow
    {_description, link, _bom} = extract_null_terminated(payload)
    link
  end

  def read_user_text(payload) do
    {description, text, bom} = extract_null_terminated(payload)

    case bom do
      nil ->
        text

      _ ->
        {description, read_utf16(bom, text)}
    end
  end

  def read_involved_people_list(<<1>>, acc) do
    acc
  end

  def read_involved_people_list(payload, acc) do
    {role, text, _bom} = extract_null_terminated(payload)
    {person, text, bom} = extract_null_terminated(<<1>> <> text)

    case bom do
      nil ->
        text

      _ ->
        people = [{role, person} | acc]
        read_involved_people_list(<<1>> <> text, people)
    end
  end

  def extract_null_terminated(<<1, rest::binary>>) do
    <<bom::binary-size(2), content::binary>> = rest
    {description, value} = scan_for_null_utf16(content, bom, [])
    {description, value, bom}
  end

  def extract_null_terminated(<<encoding::integer-8, content::binary>>) do
    {description, value} =
      case encoding do
        0 -> scan_for_null_utf8(content, [])
        3 -> scan_for_null_utf8(content, [])
        _ -> raise "I don't support that text encoding (encoding was #{encoding})"
      end

    {description, value, nil}
  end

  # Based on https://elixirforum.com/t/scanning-a-bitstring-for-a-value/1852/2
  def scan_for_null_utf16(<<c::utf16-little, rest::binary>>, <<255, 254>> = bom, accum) do
    case c do
      0 -> {to_string(Enum.reverse(accum)), rest}
      _ -> scan_for_null_utf16(rest, bom, [c | accum])
    end
  end

  def scan_for_null_utf16(<<c::utf16, rest::binary>>, <<254, 255>> = bom, accum) do
    case c do
      0 -> {to_string(Enum.reverse(accum)), rest}
      _ -> scan_for_null_utf16(rest, bom, [c | accum])
    end
  end

  defp scan_for_null_utf8(<<c::utf8, rest::binary>>, accum) do
    case c do
      0 -> {to_string(Enum.reverse(accum)), rest}
      _ -> scan_for_null_utf8(rest, [c | accum])
    end
  end

  def read_utf16("") do
    ""
  end

  def read_utf16(<<bom::binary-size(2), 0, 0, content::binary>>) do
    read_utf16(bom, content)
  end

  def read_utf16(<<bom::binary-size(2), content::binary>>) do
    read_utf16(bom, content)
  end

  # This formatting isn't valid (id3v2 spec says read encoding from front of desc
  # and has no further encoding between desc and val) but it makes sense
  # that it might be included.
  # To make up for the fact that this is invalid, we're extra stringent
  # that the binary values must match the big or little patterns.
  def read_utf16(_desc_bom, <<255, 254, content::binary>>) do
    read_utf16(<<255, 254>>, content)
  end

  def read_utf16(_desc_bom, <<254, 255, content::binary>>) do
    read_utf16(<<254, 255>>, content)
  end

  # This formatting isn't valid AFAIK, however it appears on the Sonic test case
  def read_utf16(bom, <<255, 0, 254, content::binary>>) do
    read_utf16(bom, content)
  end

  def read_utf16(bom, <<254, 0, 255, content::binary>>) do
    read_utf16(bom, content)
  end

  def read_utf16(bom, content) do
    {encoding, _charsize} = :unicode.bom_to_encoding(bom)
    :unicode.characters_to_binary(content, encoding)
  end

  def strip_zero_bytes(<<h, t::binary>>) do
    case h do
      0 -> t
      _ -> <<h, strip_zero_bytes(t)::binary>>
    end
  end

  def strip_zero_bytes(<<h>>) do
    case h do
      0 -> <<>>
      _ -> h
    end
  end

  def strip_zero_bytes(<<>>) do
    <<>>
  end
end
