defmodule ScryD3.V2.HeaderFlags do
  @moduledoc """
  Struct for the top header.

  https://id3.org/id3v2.3.0#ScryD3_header
  """
  defstruct [:unsynchronized, :extended_header, :experimental]

  @unsynchronized_bit 128
  @extended_header_bit 64
  @experimental_bit 32

  def read(byte) do
    %__MODULE__{
      experimental: 0 != Bitwise.band(byte, @experimental_bit),
      unsynchronized: 0 != Bitwise.band(byte, @unsynchronized_bit),
      extended_header: 0 != Bitwise.band(byte, @extended_header_bit)
    }
  end
end
