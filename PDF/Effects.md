Whiten PDF 

magick -density 300 "input.pdf" -colorspace gray -threshold 60% -deskew 40% "cleaned_output.pdf"



⭐Scan is too light(increase boldness)

magick -density 300 "input.pdf" -colorspace gray -level 20%,80% "bold_output.pdf"



All in one(boldness and whiteness)

magick -density 300 "input.pdf" -colorspace gray -sharpen 0x1 -level 25%,75% "best_print.pdf"

 
Write the original file name in place of input.pdf


