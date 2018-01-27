defmodule GeoTIFFTest do
  use ExUnit.Case
  doctest GeoTIFF

  test "Tag Values" do
    filename = './test/resources/example_ii.tif'
    {:ok, response} = GeoTIFF.read_headers(filename)
  end
end
