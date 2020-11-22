# ScryD3 [![Build Status](https://drone.foggy.llc/api/badges/foggy.llc/scryd3/status.svg)](https://drone.foggy.llc/foggy.llc/scryd3)

Basic ID3 tag parsing for Elixir. Currently only implements ID3v2.

## Usage

```elixir
    contents = File.read!('track.mp3')
    tag_header = ScryD3.V2.header(contents)
    {major, minor} = tag_header.version
    IO.puts "ID3 version 2.#{major}.#{minor}"

    tag_frames = ScryD3.V2.frames(contents)
    IO.puts "Track title: #{tag_frames.TIT2}"
    IO.puts "Track artist: #{tag_frames.TPE1}"
    IO.puts "Track album: #{tag_frames.TALB}"
```

## Installation

The package can be installed as:

  1. Add `scryd3` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:scryd3, "~> 0.2.0"}]
    end
    ```
    
## Attributions

ScryD3 is forked from [id3v2](https://github.com/Cheezmeister/elixir-id3v2). ScryD3 is a continuation of the work from that package.

The package source does not contain a license, but the [hex package](https://hex.pm/packages/id3v2) is explicitly licensed under ZLIB. See our inclusion of the [zlib license](ZLIB_LICENSE).

## License

ScryD3 is [licensed](LICENSE) AGPL-3.0. In addition to the terms of the included license, all modifications of this software must maintain the author's copyright claims included herein. Additionally, modifications must take steps to state clearly that they are modifications.
