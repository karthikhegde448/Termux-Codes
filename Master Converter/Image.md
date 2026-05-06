pkg update && pkg upgrade
pkg install imagemagick

magick "input.ext" "output.ext"

For multiple images
magick mogrify -format webp *.jpg
