defmodule ScryD3.V2Test do
  use ExUnit.Case

  # TODO run on several files to at least cover v2.{2,3,4}
  @sonic "test/fixtures/Sonic_the_Hedgehog_3_LatinSphere_OC_ReMix.mp3"
  @springsteen "test/fixtures/04-Western_Stars.mp3"
  @chapter_frames_fixture "test/fixtures/case_podcast_episode_20.mp3"

  test "header extraction" do
    file = File.read!(@sonic)
    header = ScryD3.V2.header(file)
    assert header.version == {4, 0}
    assert header.flags.unsynchronized
    assert header.size == 72_888
  end

  test "header unsynchronized flag" do
    assert ScryD3.V2.read_flags(128).unsynchronized
  end

  test "header extended_header flag" do
    assert ScryD3.V2.read_flags(64).extended_header
  end

  test "header experimental flag" do
    assert ScryD3.V2.read_flags(32).experimental
  end

  test "header size extraction" do
    assert ScryD3.V2.unpacked_size(<<0, 4, 62, 25>>) == 25 + 62 * 128 + 4 * 128 * 128 + 0
  end

  test "read UTF-16" do
    assert "A0" == ScryD3.V2.read_utf16(<<255, 254, 65, 00, 48, 00>>)
  end

  test "read payload ASCII/ISO-8859-1" do
    assert "pants" == ScryD3.V2.read_payload("XXXX", <<0, "pants"::utf8>>)
  end

  test "read payload UTF-16" do
    assert "pants" == ScryD3.V2.read_payload("XXXX", <<1, 255, 254, "pants"::utf16-little>>)
    assert "pants" == ScryD3.V2.read_payload("XXXX", <<1, 254, 255, "pants"::utf16-big>>)
  end

  test "read payload UTF-8" do
    assert "pants" == ScryD3.V2.read_payload("XXXX", <<3, "pants"::utf8>>)
  end

  test "extract null-terminated ascii" do
    {description, rest, bom} = ScryD3.V2.extract_null_terminated(<<3, "Wat", 00, "ABC">>)
    assert description == "Wat"
    assert rest == "ABC"
    assert bom == nil
  end

  test "extract null-terminated utf8" do
    {description, rest, bom} = ScryD3.V2.extract_null_terminated(<<3, "Wat", 00, "合"::utf8>>)
    assert description == "Wat"
    assert rest == "合"
    assert bom == nil
  end

  test "extract null-terminated utf16" do
    {description, rest, bom} =
      ScryD3.V2.extract_null_terminated(<<1, 254, 255, "Wat"::utf16, 00, 00, 65, 66, 67>>)

    assert description == "Wat"
    assert rest == "ABC"
    assert bom == <<254, 255>>
  end

  test "read user url" do
    link =
      ScryD3.V2.read_user_url(<<1, 255, 254, "Desc"::utf16-little, 00, 00, "http://bogus.url">>)

    assert link == "http://bogus.url"
  end

  test "read user text" do
    {desc, value} =
      ScryD3.V2.read_user_text(
        <<1, 255, 254, "Desc"::utf16-little, 00, 00, "Value"::utf16-little>>
      )

    assert desc == "Desc"
    assert value == "Value"
  end

  test "read user text utf8" do
    text = ScryD3.V2.read_user_text(<<3, "Desc", 00, "Value">>)
    assert text == "Value"
  end

  test "read involved people list" do
    [{role1, person1}, {role2, person2}] =
      ScryD3.V2.read_involved_people_list(
        <<1, 255, 254, "trumpet"::utf16-little, 00, 00, 255, 254, "Clifford Brown"::utf16-little,
          00, 00, 255, 254, "piano"::utf16-little, 00, 00, 255, 254,
          "Horace Silver"::utf16-little, 00, 00>>,
        []
      )

    assert role2 == "trumpet"
    assert person2 == "Clifford Brown"
    assert role1 == "piano"
    assert person1 == "Horace Silver"
  end

  test "strip zero bytes" do
    assert ScryD3.V2.strip_zero_bytes(<<0>>) == <<>>
    assert ScryD3.V2.strip_zero_bytes(<<>>) == <<>>
  end

  test "strip zero bytes complex" do
    assert ScryD3.V2.strip_zero_bytes(<<0, 255>>) == <<255>>
    assert ScryD3.V2.strip_zero_bytes(<<255, 0>>) == <<255>>
    assert ScryD3.V2.strip_zero_bytes(<<255, 255>>) == <<255, 255>>
    assert ScryD3.V2.strip_zero_bytes(<<255, 0, 255>>) == <<255, 255>>
    assert ScryD3.V2.strip_zero_bytes(<<0, 255, 255>>) == <<255, 255>>
    assert ScryD3.V2.strip_zero_bytes(<<255, 255, 0>>) == <<255, 255>>
  end

  test "frame data - #{@sonic}" do
    frames = ScryD3.V2.frames(File.read!(@sonic))
    assert frames["TPUB"] == "OverClocked ReMix"
  end

  test "frame data - #{@springsteen}" do
    frames = ScryD3.V2.frames(File.read!(@springsteen))
    assert frames["TPUB"] == "Columbia"
  end

  test "chapter frames - #{@chapter_frames_fixture}" do
    expected_chapter_frames = %{
      "CHAP:chp0" => %{
        end_offset: 4_294_967_295,
        end_time: 21000,
        start_offset: 4_294_967_295,
        start_time: 0,
        title: "Introduction"
      },
      "CHAP:chp1" => %{
        end_offset: 4_294_967_295,
        end_time: 100_000,
        start_offset: 4_294_967_295,
        start_time: 21000,
        title: "Why Clojure?"
      },
      "CHAP:chp10" => %{
        end_offset: 4_294_967_295,
        end_time: 1_824_000,
        start_offset: 4_294_967_295,
        start_time: 1_688_000,
        title: "Safety Critical Systems & Spec ??"
      },
      "CHAP:chp11" => %{
        end_offset: 4_294_967_295,
        end_time: 2_068_000,
        start_offset: 4_294_967_295,
        start_time: 1_824_000,
        title: "Datomic"
      },
      "CHAP:chp12" => %{
        end_offset: 4_294_967_295,
        end_time: 2_208_000,
        start_offset: 4_294_967_295,
        start_time: 2_068_000,
        title: "Opinionated Web Frameworks"
      },
      "CHAP:chp13" => %{
        end_offset: 4_294_967_295,
        end_time: 2_567_000,
        start_offset: 4_294_967_295,
        start_time: 2_208_000,
        title: "Problems left to solve…"
      },
      "CHAP:chp14" => %{
        end_offset: 4_294_967_295,
        end_time: 2_773_000,
        start_offset: 4_294_967_295,
        start_time: 2_567_000,
        title: "System Level Communication"
      },
      "CHAP:chp15" => %{
        end_offset: 4_294_967_295,
        end_time: 2_988_000,
        start_offset: 4_294_967_295,
        start_time: 2_773_000,
        title: "A functional approach to programming"
      },
      "CHAP:chp16" => %{
        end_offset: 4_294_967_295,
        end_time: 3_191_000,
        start_offset: 4_294_967_295,
        start_time: 2_988_000,
        title: "How to efficiently develop programming"
      },
      "CHAP:chp17" => %{
        end_offset: 4_294_967_295,
        end_time: 3_417_000,
        start_offset: 4_294_967_295,
        start_time: 3_191_000,
        title: "Finding the right problem"
      },
      "CHAP:chp18" => %{
        end_offset: 4_294_967_295,
        end_time: 3_599_996,
        start_offset: 4_294_967_295,
        start_time: 3_417_000,
        title: "Technical things to research"
      },
      "CHAP:chp2" => %{
        end_offset: 4_294_967_295,
        end_time: 201_000,
        start_offset: 4_294_967_295,
        start_time: 100_000,
        title: "What problems does Clojure solve?"
      },
      "CHAP:chp3" => %{
        end_offset: 4_294_967_295,
        end_time: 260_000,
        start_offset: 4_294_967_295,
        start_time: 201_000,
        title: "Platforms that Clojure runs on"
      },
      "CHAP:chp4" => %{
        end_offset: 4_294_967_295,
        end_time: 354_000,
        start_offset: 4_294_967_295,
        start_time: 260_000,
        title: "Clojure on the JVM"
      },
      "CHAP:chp5" => %{
        end_offset: 4_294_967_295,
        end_time: 461_000,
        start_offset: 4_294_967_295,
        start_time: 354_000,
        title: "Clojure 1.9: Spec & Tools"
      },
      "CHAP:chp6" => %{
        end_offset: 4_294_967_295,
        end_time: 617_000,
        start_offset: 4_294_967_295,
        start_time: 461_000,
        title: "Installer & Command Line Tools"
      },
      "CHAP:chp7" => %{
        end_offset: 4_294_967_295,
        end_time: 1_166_000,
        start_offset: 4_294_967_295,
        start_time: 617_000,
        title: "Dependency Problem"
      },
      "CHAP:chp8" => %{
        end_offset: 4_294_967_295,
        end_time: 1_383_000,
        start_offset: 4_294_967_295,
        start_time: 1_166_000,
        title: "Designing functions to allow change"
      },
      "CHAP:chp9" => %{
        end_offset: 4_294_967_295,
        end_time: 1_688_000,
        start_offset: 4_294_967_295,
        start_time: 1_383_000,
        title: "Clojure Spec"
      }
    }

    frames = ScryD3.V2.frames(File.read!(@chapter_frames_fixture))
    chapter_frames = :maps.filter(fn key, _ -> String.starts_with?(key, "CHAP:") end, frames)
    assert expected_chapter_frames == chapter_frames
  end
end
