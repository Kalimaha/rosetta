defmodule GeoTIFFFormatterTest do
  use ExUnit.Case

  test 'format headers' do
    expected_text = """
   
    ====================================================
    Filename: spam.tiff
    Endianess: little
    First IFD: 42

    Available IFDs

    ====================================================
    """
    headers = %{ 
      :filename => 'spam.tiff', 
      :endianess => :little, 
      :first_ifd_offset => 42,
      :ifds => []
    }

    assert GeoTIFFFormatter.format_headers(headers) == expected_text
  end

  test 'format IFD' do
    expected_text = """
    ----------------------------------------------------
    Offset: 42
    Entries: 100
    Next IFD: 82

    Spam [text]: eggs {count: 42}  
    ----------------------------------------------------
    """
    tag = %{ :tag => 'Spam', :type => 'text', :value => "eggs", :count => 42 }
    ifd = %{ :offset => 42, :entries => 100, :next_ifd => 82, :tags => [ tag ] }

    assert GeoTIFFFormatter.format_ifd(ifd) == expected_text
  end

  test 'format tag' do
    tag = %{ :tag => 'Spam', :type => 'text', :value => "eggs", :count => 42 }
    expected_text = "Spam [text]: eggs {count: 42}"

    assert GeoTIFFFormatter.format_tag(tag) == expected_text
  end
end
