defmodule ScryD3.FrameHeaderFlags do
  @moduledoc """
  Struct for the frame headers.

  https://id3.org/id3v2.3.0#Frame_header_flags
  """
  use Bitwise

  defstruct [
    :tag_alter_preservation,
    :file_alter_preservation,
    :read_only,
    :grouping_identity,
    :compression,
    :encryption,
    :unsynchronisation,
    :data_length_indicator
  ]

  @tag_alter_preservation_bit 1 <<< 15
  @file_alter_preservation_bit 1 <<< 14
  @read_only_bit 1 <<< 13
  @grouping_identity_bit 16
  @compression_bit 8
  @encryption_bit 4
  @unsynchronisation_bit 2
  @data_length_indicator_bit 1

  def read(<<doublebyte::integer-16>>) do
    %ScryD3.FrameHeaderFlags{
      read_only: 0 != (doublebyte &&& @read_only_bit),
      tag_alter_preservation: 0 != (doublebyte &&& @tag_alter_preservation_bit),
      file_alter_preservation: 0 != (doublebyte &&& @file_alter_preservation_bit),
      grouping_identity: 0 != (doublebyte &&& @grouping_identity_bit),
      compression: 0 != (doublebyte &&& @compression_bit),
      encryption: 0 != (doublebyte &&& @encryption_bit),
      unsynchronisation: 0 != (doublebyte &&& @unsynchronisation_bit),
      data_length_indicator: 0 != (doublebyte &&& @data_length_indicator_bit)
    }
  end
end
