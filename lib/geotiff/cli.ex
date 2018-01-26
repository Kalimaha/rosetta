defmodule GeoTIFF.CLI do
  @moduledoc """
  What about now?
  """
  def main(argv) do
    # GeoTIFFFormatter.inspect argv[0]
    parse_args(argv)
  end

  @doc """
  Hallo, world?
  """
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])
    case parse do
      { [help: true], _, _ } -> help() |> IO.puts
      { _, [ filename ], _ } -> GeoTIFF.inspect filename
      _ -> help() |> IO.puts
    end
  end

  defp help do
    """
    Usage:

      ./rosetta <FILENAME>

    By default, the script will display the TIFF headers.
    """
  end
end
