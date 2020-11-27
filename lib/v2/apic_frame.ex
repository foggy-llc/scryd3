defmodule ScryD3.V2.ApicFrame do
  @moduledoc """
  Parses attached picture frame data.

  https://id3.org/id3v2.3.0#Attached_picture
  """

  require Logger

  @picture_types %{
    0x00 => "Other",
    0x01 => "32x32 pixels 'file icon' (PNG only)",
    0x02 => "Other file icon",
    0x03 => "Cover (front)",
    0x04 => "Cover (back)",
    0x05 => "Leaflet page",
    0x06 => "Media (e.g. lable side of CD)",
    0x07 => "Lead artist/lead performer/soloist",
    0x08 => "Artist/performer",
    0x09 => "Conductor",
    0x0A => "Band/Orchestra",
    0x0B => "Composer",
    0x0C => "Lyricist/text writer",
    0x0D => "Recording Location",
    0x0E => "During recording",
    0x0F => "During performance",
    0x10 => "Movie/video screen capture",
    0x11 => "A bright coloured fish",
    0x12 => "Illustration",
    0x13 => "Band/artist logotype",
    0x14 => "Publisher/Studio logotype"
  }

  # Some things will be missing encoding (sonic test case again).
  def read(<<encoding::integer-8, payload::binary>>) when encoding > 2 do
    read(<<0>> <> payload)
  end

  def read(<<encoding::binary-size(1), payload::binary>>) do
    {mime, rest, _} = ScryD3.V2.extract_null_terminated(<<0>> <> payload)
    <<type_code, picture_data::binary>> = rest
    picture_type = @picture_types[type_code]

    {description, picture_data, _} =
      try do
        ScryD3.V2.extract_null_terminated(encoding <> picture_data)
      rescue
        e ->
          Logger.debug("Image lacking description! #{inspect(e)}")
          {nil, picture_data, nil}
      end

    {picture_type,
     %{
       mime_type: mime,
       picture_type: picture_type,
       description: description,
       picture_data: picture_data,
       text_encoding: encoding
     }}
  end
end
