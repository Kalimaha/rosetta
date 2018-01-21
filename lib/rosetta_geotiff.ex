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
