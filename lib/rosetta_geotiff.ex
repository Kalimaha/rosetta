defmodule RosettaGeoTIFF do
  def read_headers(filename) do
    with {:ok, file} <- :file.open(filename, [:read, :binary]),
         {:ok, header_bytes} <- header_bytes(file),
         {:ok, endianess} <- endianess(header_bytes),
         first_ifd <- first_ifd(header_bytes, endianess) do
      {:ok, %{:endianess => endianess, :first_ifd => first_ifd}}
    else
      {:error, reason} -> {:error, format_error(filename, reason)}
    end
  end

  @doc ~S"""
  Reads the header (first 8 bytes) of the TIFF file.

  ### Examples:

    iex> filename = "./test/resources/example.tif"
    iex> {:ok, file} = :file.open(filename, [:read, :binary])
    iex> RosettaGeoTIFF.header_bytes(file)
    {:ok, <<73, 73, 42, 0, 196, 31, 4, 0>>}
  """
  def header_bytes(file) do
    :file.position(file, 0)
    bytes = :file.read(file, 8)
    :file.close(file)

    bytes
  end

  @doc ~S"""
  Determines the endianess of the bytes from the first two bytes of the header.

  ### Examples:

    iex> RosettaGeoTIFF.endianess(<<73, 73>>)
    {:ok, :little}

    iex> RosettaGeoTIFF.endianess(<<77, 77>>)
    {:ok, :big}

    iex> RosettaGeoTIFF.endianess(<<105, 105>>)
    {:error, "Cannot determine endianess for 'ii'."}
  """
  def endianess(header_bytes) do
    :binary.bin_to_list(header_bytes, {0, 2})
    |> :erlang.list_to_binary()
    |> order2endianess
  end

  @doc ~S"""
  Determines the address of the first IFD of the file.

  ### Examples:

    iex> header_bytes = <<0, 0, 0, 0, 0, 0, 0, 42>>
    iex> RosettaGeoTIFF.first_ifd(header_bytes, :little)
    704_643_072

    iex> header_bytes = <<0, 0, 0, 0, 42, 0, 0, 0>>
    iex> RosettaGeoTIFF.first_ifd(header_bytes, :big)
    704_643_072
  """
  def first_ifd(header_bytes, endianness) do
    :binary.bin_to_list(header_bytes, {4, 4})
    |> :erlang.list_to_binary()
    |> :binary.decode_unsigned(endianness)
  end

  defp order2endianess(order) do
    case order do
      "II" -> {:ok, :little}
      "MM" -> {:ok, :big}
      _ -> {:error, "Cannot determine endianess for '#{order}'."}
    end
  end

  defp format_error(filename, reason) do
    "Failed to open file '#{filename}'. Reason: #{reason}."
  end
end
