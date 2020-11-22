defmodule ScryD3.V2.ApicFrame do
  @moduledoc """
  Parses attached picture frame data.

  https://id3.org/id3v2.3.0#Attached_picture
  """

  @picture_types %{
    "0x00" => "Other",
    "0x01" => "32x32 pixels 'file icon' (PNG only)",
    "0x02" => "Other file icon",
    "0x03" => "Cover (front)",
    "0x04" => "Cover (back)",
    "0x05" => "Leaflet page",
    "0x06" => "Media (e.g. lable side of CD)",
    "0x07" => "Lead artist/lead performer/soloist",
    "0x08" => "Artist/performer",
    "0x09" => "Conductor",
    "0x0A" => "Band/Orchestra",
    "0x0B" => "Composer",
    "0x0C" => "Lyricist/text writer",
    "0x0D" => "Recording Location",
    "0x0E" => "During recording",
    "0x0F" => "During performance",
    "0x10" => "Movie/video screen capture",
    "0x11" => "A bright coloured fish",
    "0x12" => "Illustration",
    "0x13" => "Band/artist logotype",
    "0x14" => "Publisher/Studio logotype"
  }
  
end
