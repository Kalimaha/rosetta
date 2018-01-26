defmodule GeoTIFFTags do
  @tag_codes  "./lib/resources/tag_codes.json"
  @data_types "./lib/resources/data_types.json"

  @doc ~S"""
  Returns the tag name from the tag code.

  ### Examples:

    iex> GeoTIFFTags.decode_tag_name(256)
    "ImageWidth"

    iex> GeoTIFFTags.decode_tag_name(666)
    666
  """
  def decode_tag_name(tag_code) do
    File.read!(@tag_codes)
    |> Poison.decode!
    |> label_or_code(tag_code)
  end

  @doc ~S"""
  Returns the data type from its code.

  ### Examples:

    # iex> GeoTIFFTags.decode_data_type(3)
    # "SHORT"

    iex> GeoTIFFTags.decode_data_type(666)
    666
  """
  def decode_data_type(data_type_code) do
    File.read!(@data_types)
    |> Poison.decode!
    |> label_or_code(data_type_code)
  end

  defp label_or_code(mapping, code), do: mapping[Integer.to_string code] || code
end
