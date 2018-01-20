defmodule RosettaGeoTIFF do
  def read_headers(filename) do
    with {:ok, file} <- :file.open(filename, [:read, :binary]),
         {:ok, header_bytes} <- header_bytes(file) do
      order = order(header_bytes)
      first_ifd = first_ifd(header_bytes, order)

      {:ok, %{:order => order, :first_ifd => first_ifd}}
    else
      {:error, reason} -> {:error, format_error(filename, reason)}
    end
  end

  defp header_bytes(file) do
    :file.position(file, 0)
    bytes = :file.read(file, 8)
    :file.close(file)

    bytes
  end

  defp order(header_bytes) do
    :binary.bin_to_list(header_bytes, {0, 2})
    |> :erlang.list_to_binary()
  end

  defp first_ifd(header_bytes, order) do
    case order do
      "II" -> decode_first_ifd(header_bytes, :little)
      "MM" -> decode_first_ifd(header_bytes, :big)
    end
  end

  defp decode_first_ifd(header_bytes, endianness) do
    :binary.bin_to_list(header_bytes, {4, 4})
    |> :erlang.list_to_binary()
    |> :binary.decode_unsigned(endianness)
  end

  defp format_error(filename, reason) do
    "Failed to open file '#{filename}'. Reason: #{reason}."
  end
end
