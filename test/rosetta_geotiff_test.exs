defmodule RosettaGeoTIFFTest do
  use ExUnit.Case
  doctest RosettaGeoTIFF

  setup_all do
    {:ok, filename: "./test/resources/example.tif"}
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
end
