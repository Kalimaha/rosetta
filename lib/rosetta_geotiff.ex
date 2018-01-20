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
    list = :binary.bin_to_list(header_bytes)

    <<Enum.at(list, 0), Enum.at(list, 1)>>
  end

  defp first_ifd(header_bytes, order) do
    case order do
      "II" -> decode_II(header_bytes)
      "MM" -> decode_MM(header_bytes)
    end
  end

  defp decode_II(header_bytes) do
    list = :binary.bin_to_list(header_bytes)

    :binary.decode_unsigned(
      <<Enum.at(list, 7), Enum.at(list, 6), Enum.at(list, 5), Enum.at(list, 4)>>
    )
  end

  defp decode_MM(header_bytes) do
    list = :binary.bin_to_list(header_bytes)

    :binary.decode_unsigned(
      <<Enum.at(list, 4), Enum.at(list, 5), Enum.at(list, 6), Enum.at(list, 7)>>
    )
  end

  defp format_error(filename, reason) do
    "Failed to open file '#{filename}'. Reason: #{reason}."
  end
end
