# ScryD3 [![Build Status](https://drone.foggy.llc/api/badges/foggy.llc/elixir-id3v2/status.svg?ref=refs/heads/main)](https://drone.foggy.llc/foggy.llc/elixir-id3v2)

Basic ScryD3 tag parsing for Elixir. This is a work in progress.

Be prepared to *Use the Source, Luke*. Expect bugs.

## Usage

```elixir
    contents = File.read!('track.mp3')
    tag_header = ScryD3.header(contents)
    {major, minor} = tag_header.version
    IO.puts "ID3 version 2.#{major}.#{minor}"

    tag_frames = ScryD3.frames(contents)
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
