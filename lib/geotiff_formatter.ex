defmodule GeoTIFFFormatter do
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
  
  def format_tag(tag) do
    if is_list(tag.value) do
      "#{tag.tag} [#{tag.type}]: OFFSET {count: #{tag.count}}"
    else
      "#{tag.tag} [#{tag.type}]: #{tag.value} {count: #{tag.count}}"
    end
  end
end
