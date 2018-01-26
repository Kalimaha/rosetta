defmodule GeoTIFF do
  @doc ~S"""
  Reads the headers of a GeoTIFF file.

  ### Examples:

    iex> filename = "./test/resources/example.tif"
    iex> GeoTIFF.read_headers(filename)
    {:ok, %{:endianess => :little, :first_ifd_offset => 270_276}}

    iex> filename = "spam.eggs"
    iex> GeoTIFF.read_headers(filename)
    {:error, "Failed to open file 'spam.eggs'. Reason: enoent."}
  """
  def read_headers(filename) do
    with {:ok, file}          <- :file.open(filename, [:read, :binary]),
         {:ok, header_bytes}  <- header_bytes(file),
         {:ok, endianess}     <- endianess(header_bytes),
         first_ifd_offset     <- first_ifd_offset(header_bytes, endianess) do
         # {:ok, ifds}          <- parse_ifds(file, first_ifd_offset, endianess) do

      :file.close(file)
      {:ok, %{:endianess => endianess, :first_ifd_offset => first_ifd_offset}}
    else
      {:error, reason} -> {:error, format_error(filename, reason)}
    end
  end

  @doc ~S"""
  Decodes the IFDs of a TIFF file.

  ### Examples:

    iex> {:ok, file} = :file.open('./test/resources/example.tif', [:read, :binary])
    iex> ifds = GeoTIFF.parse_ifds(file, 270_276, :little)
    iex> length ifds
    1
  """
  def parse_ifds(file, first_ifd_offset, endianess) do
    ifd = parse_ifd(file, first_ifd_offset, endianess)

    [ifd]
  end

  @doc ~S"""
  Decodes a single IFD.

  ### Examples:

    iex> {:ok, file} = :file.open('./test/resources/example.tif', [:read, :binary])
    iex> ifd = GeoTIFF.parse_ifd(file, 270_276, :little)
    iex> ifd.entries
    16
    iex> ifd.next_ifd
    0
    iex> length ifd.tags
    16
  """
  def parse_ifd(file, ifd_offset, endianess) do
    entries = ifd_entries(file, ifd_offset, endianess)
    :file.position(file, 2 + ifd_offset)
    {:ok, bytes} = :file.read(file, entries * 12 + 4)
    tags = Enum.map 0..15, &(read_tag(bytes, 12 * &1, endianess))
    next_ifd = decode(bytes, {entries * 12, 4}, endianess)

    %{:entries => entries, :tags => tags, :next_ifd => next_ifd}
  end

  @doc ~S"""
  Decodes a single TIFF tag.

  ### Examples:

    iex> bytes = <<0, 1, 3, 0, 1, 0, 0, 0, 2, 2, 0, 0>>
    iex> GeoTIFF.read_tag(bytes, 0, :little)
    %{count: 1, tag: "ImageWidth", type: "SHORT", value: 514}
  """
  def read_tag(bytes, offset, endianess) do
    %{
      :tag   => decode(bytes, {offset + 0, 2}, endianess) |> tag_name(),
      :type  => decode(bytes, {offset + 2, 2}, endianess) |> data_type(),
      :count => decode(bytes, {offset + 4, 4}, endianess),
      :value => decode(bytes, {offset + 8, 4}, endianess)
    }
  end


  @doc ~S"""
  Determines how many entries are avilable for a given IFD.

  ### Examples:

    iex> {:ok, file} = :file.open('./test/resources/example.tif', [:read, :binary])
    iex> GeoTIFF.ifd_entries(file, 270_276, :little)
    16
  """
  def ifd_entries(file, offset, endianess) do
    :file.position(file, offset)
    {:ok, entries_bytes} = :file.read(file, 2)
    decode(entries_bytes, {0, 2}, endianess)
  end

  @doc ~S"""
  Decodes a subset of bytes.

  ### Examples:

    iex> GeoTIFF.decode(<<73, 73, 42, 0, 196, 31, 4, 0>>, {4, 3}, :little)
    270_276
  """
  def decode(bytes, range, endianess) do
    :binary.bin_to_list(bytes, range)
    |> :erlang.list_to_binary
    |> :binary.decode_unsigned(endianess)
  end

  @doc ~S"""
  Reads the header (first 8 bytes) of the TIFF file.

  ### Examples:

    iex> filename = "./test/resources/example.tif"
    iex> {:ok, file} = :file.open(filename, [:read, :binary])
    iex> GeoTIFF.header_bytes(file)
    {:ok, <<73, 73, 42, 0, 196, 31, 4, 0>>}
  """
  def header_bytes(file) do
    :file.position(file, 0)
    :file.read(file, 8)
  end

  @doc ~S"""
  Determines the endianess of the bytes from the first two bytes of the header.

  ### Examples:

    iex> GeoTIFF.endianess(<<73, 73>>)
    {:ok, :little}

    iex> GeoTIFF.endianess(<<77, 77>>)
    {:ok, :big}

    iex> GeoTIFF.endianess(<<105, 105>>)
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
    iex> GeoTIFF.first_ifd_offset(header_bytes, :little)
    704_643_072

    iex> header_bytes = <<0, 0, 0, 0, 42, 0, 0, 0>>
    iex> GeoTIFF.first_ifd_offset(header_bytes, :big)
    704_643_072
  """
  def first_ifd_offset(header_bytes, endianness) do
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

  defp tag_name(code) do
    case code do
      262 -> "PhotometricInterpretation"
      256 -> "ImageWidth"
      257 -> "ImageLength"
      258 -> "BitsPerSample"
      259 -> "Compression"
      273 -> "StripsOffset"
      277 -> "SamplesPerPixel"
      278 -> "RowsPerStrip"
      279 -> "StripByteCounts"
      284 -> "PlanarConfiguration"
      339 -> "SampleFormat"
      33550 -> "ModelPixelScaleTag"
      33922 -> "ModelTiepointTag"
      34735 -> "GeoKeyDirectoryTag"
      34736 -> "GeoDoubleParamsTag"
      34737 -> "GeoAsciiParamsTag"
        _ -> code
    end
  end

  defp data_type(code) do
    case code do
         1 -> "BYTE"
         2 -> "ASCII"
         3 -> "SHORT"
         4 -> "LONG"
         5 -> "RATIONALE"
         6 -> "SBYTE"
         7 -> "UNDEFINED"
         8 -> "SSHORT"
         9 -> "SLONG"
        10 -> "SRATIONAL"
        11 -> "FLOAT"
        12 -> "DOUBLE"
         _ -> code
    end
  end
end
