defmodule GeoTIFFFormatter do
  @doc ~S"""
  Formats a single IFD.

  ### Examples:

    iex> tag = %{:tag => "Spam", :type => "EGGS", :value => 42, :count => 1}
    iex> ifd = %{:offset => 42, :entries => 42, :next_ifd => 0, :tags => [tag]}
    iex> headers = %{:filename => 'spam', :endianess => :little, :first_ifd_offset => 42, :ifds => [ifd]}
    iex> GeoTIFFFormatter.format_headers headers
    "\n====================================================\nFilename: spam\nEndianess: little\nFirst IFD: 42\n\nAvailable IFDs\n----------------------------------------------------\n  Offset: 42\n  Entries: 42\n  Next IFD: 0\n\n  Spam [EGGS]: 42 {count: 1}\n----------------------------------------------------\n\n====================================================\n"
  """
  def format_headers(headers) do
    """

    ====================================================
    Filename: #{headers.filename}
    Endianess: #{headers.endianess}
    First IFD: #{headers.first_ifd_offset}

    Available IFDs
    #{Enum.map headers.ifds, &(format_ifd(&1))}
    ====================================================
    """
  end

  @doc ~S"""
  Formats a single IFD.

  ### Examples:

    iex> tag = %{:tag => "Spam", :type => "EGGS", :value => 42, :count => 1}
    iex> ifd = %{:offset => 42, :entries => 42, :next_ifd => 0, :tags => [tag]}
    iex> GeoTIFFFormatter.format_ifd ifd
    "----------------------------------------------------\n  Offset: 42\n  Entries: 42\n  Next IFD: 0\n\n  Spam [EGGS]: 42 {count: 1}\n----------------------------------------------------\n"
  """
  def format_ifd(ifd) do
    """
    ----------------------------------------------------
      Offset: #{ifd.offset}
      Entries: #{ifd.entries}
      Next IFD: #{ifd.next_ifd}

    #{Enum.map(ifd.tags, &(format_tag(&1))) |> Enum.join("\n")}
    ----------------------------------------------------
    """
  end

  @doc ~S"""
  Formats a single TIFF tag.

  ### Examples:

    iex> tag = %{:tag => "Spam", :type => "EGGS", :value => 42, :count => 1}
    iex> GeoTIFFFormatter.format_tag tag
    "  Spam [EGGS]: 42 {count: 1}"

    iex> tag = %{:tag => "Spam", :type => "EGGS", :value => [4, 2, 42], :count => 12}
    iex> GeoTIFFFormatter.format_tag tag
    "  Spam [EGGS]: [4, 2, 42] {count: 12}"
  """
  def format_tag(tag) do
    cond do
      is_list(tag.value) ->
        "  #{tag.tag} [#{tag.type}]: #{"[" <> (Enum.join tag.value, ", ") <> "]"} {count: #{tag.count}}"
      true ->
        "  #{tag.tag} [#{tag.type}]: #{tag.value} {count: #{tag.count}}"
    end
  end
end
