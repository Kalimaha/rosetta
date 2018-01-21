defmodule RosettaGeoTIFF do
  def explore(filename) do
    {:ok, header} = read_headers(filename)
    IO.puts "\tEndianess: #{header[:endianess]}\n\t1st IFD: #{header[:first_ifd]}"
    
    read_ifd(filename, header[:first_ifd], header[:endianess])
  end

  def read_ifd(filename, offset, endianess) do
    entries = ifd_entries(filename, offset, endianess)

    {:ok, file} = :file.open(filename, [:read, :binary])
    :file.position(file, 2 + offset)
    {:ok, bytes} = :file.read(file, entries * 12 + 4)
    :file.close(filename)

    next = decode(bytes, {entries * 12, 4}, endianess)
    IO.puts "Next IFD? #{next}"

    Enum.each 0..15, &(read_tag(bytes, 12 * &1, endianess))
  end

  def ifd_entries(filename, offset, endianess) do
    {:ok, file} = :file.open(filename, [:read, :binary])
    :file.position(file, offset)
    {:ok, entries_bytes} = :file.read(file, 2)
    entries = decode(entries_bytes, {0, 2}, endianess)
    :file.close(filename)

    entries
  end

  def read_tag(bytes, offset, endianess) do
    tag = decode(bytes, {offset + 0, 2}, endianess) |> tag_name()
    tag_type = decode(bytes, {offset + 2, 2}, endianess) |> data_type()
    count = decode(bytes, {offset + 4, 4}, endianess)
    data = decode(bytes, {offset + 8, 4}, endianess)
    IO.puts "Tag: #{tag}, Type: #{tag_type}, Count: #{count}, Value: #{data}"
  end

  def tag_name(code) do
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

  def data_type(code) do
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

  def decode(bytes, range, endianess) do
    :binary.bin_to_list(bytes, range)
    |> :erlang.list_to_binary
    |> :binary.decode_unsigned(endianess)
  end

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

  def header_bytes(file) do
    :file.position(file, 0)
    bytes = :file.read(file, 8)
    :file.close(file)

    bytes
  end

  def endianess(header_bytes) do
    :binary.bin_to_list(header_bytes, {0, 2})
    |> :erlang.list_to_binary()
    |> order2endianess
  end

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
