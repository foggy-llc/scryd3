# ID3v2 [![Build Status][drone-badge]

Basic ID3v2 tag parsing for Elixir. This is a work in progress.

Be prepared to *Use the Source, Luke*. Expect bugs.

## Usage

```elixir
    contents = File.read!('track.mp3')
    tag_header = ID3v2.header(contents)
    {major, minor} = tag_header.version
    IO.puts "ID3 version 2.#{major}.#{minor}"

    tag_frames = ID3v2.frames(contents)
    IO.puts "Track title: #{tag_frames.TIT2}"
    IO.puts "Track artist: #{tag_frames.TPE1}"
    IO.puts "Track album: #{tag_frames.TALB}"
```

## Installation

The package can be installed as:

  1. Add `id3v2` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:id3v2, git: "https://gitea.foggy.llc:443/foggy.llc/elixir-id3v2.git", tag: "v0.1.4"}]
    end
    ```

[drone-badge]: http://drone.foggy.llc/api/badges/foggy.llc/elixir-id3v2/status.svg?ref=refs/heads/main)](http://drone.foggy.llc/foggy.llc/elixir-id3v2
