defmodule GeoTIFF do
  @doc ~S"""
  Reads the headers of a GeoTIFF file.

  ### Examples:

    iex> filename = "./test/resources/example.tif"
    iex> {:ok, response} = GeoTIFF.read_headers(filename)
    iex> response.first_ifd_offset
    270_276

    iex> filename = "spam.eggs"
    iex> GeoTIFF.read_headers(filename)
    {:error, "Failed to open file 'spam.eggs'. Reason: enoent."}
  """
  def read_headers(filename) do
    with {:ok, file}          <- :file.open(filename, [:read, :binary]),
         {:ok, header_bytes}  <- header_bytes(file),
         {:ok, endianess}     <- endianess(header_bytes),
         first_ifd_offset     <- first_ifd_offset(header_bytes, endianess),
         ifds                 <- parse_ifds(file, first_ifd_offset, endianess, []) do

      :file.close(file)
      {:ok, %{:filename => filename, :endianess => endianess, :first_ifd_offset => first_ifd_offset, :ifds => ifds}}
    else
      {:error, reason} -> {:error, format_error(filename, reason)}
    end
  end

  def inspect(filename) do
    read_headers(filename)
    |> case do
      {:ok, headers} -> GeoTIFFFormatter.format_headers(headers) |> IO.puts
      {:error, message} -> IO.puts message
    end
  end

  @doc ~S"""
  Decodes the IFDs of a TIFF file.

  ### Examples:

    iex> {:ok, file} = :file.open('./test/resources/example.tif', [:read, :binary])
    iex> ifds = GeoTIFF.parse_ifds(file, 270_276, :little, [])
    iex> length ifds
    1
  """
  def parse_ifds(file, ifd_offset, endianess, ifds) do
    with ifd <- parse_ifd(file, ifd_offset, endianess) do
      case ifd.next_ifd do
        0 -> [ifd | ifds]
        _ -> ifds ++ parse_ifds(file, ifd.next_ifd, endianess, ifds)
      end
    end
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
    tags = Enum.map(0..15, &(read_tag(bytes, 12 * &1, endianess))) |> Enum.sort(&(&1.tag <= &2.tag))
    next_ifd = decode(bytes, {entries * 12, 4}, endianess)

    %{:offset => ifd_offset, :entries => entries, :tags => tags, :next_ifd => next_ifd}
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
      :tag   => decode(bytes, {offset + 0, 2}, endianess) |> GeoTIFFTags.decode_tag_name(),
      :type  => decode(bytes, {offset + 2, 2}, endianess) |> GeoTIFFTags.decode_data_type(),
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

  defp format_error(filename, reason), do: "Failed to open file '#{filename}'. Reason: #{reason}."
end
