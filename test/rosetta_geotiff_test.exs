defmodule RosettaGeoTIFFTest do
  use ExUnit.Case

  setup_all do
    {:ok, filename: "./test/resources/example.tif"}
  end

  test "explore file", context do
    RosettaGeoTIFF.explore(context[:filename])
  end

  test "opens the file", context do
    {:ok, headers} = RosettaGeoTIFF.read_headers(context[:filename])

    assert headers[:endianess] == :little
    assert headers[:first_ifd] == 270_276
  end

  describe "when the file does NOT exist" do
    setup do
      {:ok, filename: "spam.eggs"}
    end

    test "returns the error", context do
      msg = "Failed to open file '#{context[:filename]}'. Reason: enoent."

      assert RosettaGeoTIFF.read_headers(context[:filename]) == {:error, msg}
    end
  end

  test "read first 8 bytes", context do
    {:ok, file} = :file.open(context[:filename], [:read, :binary])
    expected = {:ok, <<73, 73, 42, 0, 196, 31, 4, 0>>}
    bytes = RosettaGeoTIFF.header_bytes(file)

    assert bytes == expected
  end

  test "determines the endianess" do
    ii_bytes = <<73, 73>>
    mm_bytes = <<77, 77>>

    assert RosettaGeoTIFF.endianess(ii_bytes) == {:ok, :little}
    assert RosettaGeoTIFF.endianess(mm_bytes) == {:ok, :big}
  end

  test "when the endianess cannot be determined" do
    bytes = <<105, 105>>
    msg = "Cannot determine endianess for 'ii'."

    assert RosettaGeoTIFF.endianess(bytes) == {:error, msg}
  end

  test "finds the first IFD for II files" do
    header_bytes = <<0, 0, 0, 0, 0, 0, 0, 42>>

    assert RosettaGeoTIFF.first_ifd(header_bytes, :little) == 704_643_072
  end

  test "finds the first IFD for MM files" do
    header_bytes = <<0, 0, 0, 0, 42, 0, 0, 0>>

    assert RosettaGeoTIFF.first_ifd(header_bytes, :big) == 704_643_072
  end
end
