[![Build Status](https://travis-ci.org/Kalimaha/rosetta.svg?branch=master)](https://travis-ci.org/Kalimaha/rosetta)
[![Coverage Status](https://coveralls.io/repos/github/Kalimaha/rosetta/badge.svg?branch=master)](https://coveralls.io/github/Kalimaha/rosetta?branch=master)

# Rosetta

Elixir project to read from different raster image formats, such as TIFF, GeoTIFF, JPEG2000 etc. The project has been named after the [Rosetta Stone](https://en.wikipedia.org/wiki/Rosetta_Stone), that helped deciphering Egyptian hieroglyphs.

## Distribution
To create the executable file:

```
mix escript.build
```

An example of usage, to display TIFF's headers:

```
./rosetta <FILENAME>.tiff
```
