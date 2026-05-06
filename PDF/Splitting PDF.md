pkg install qpdf

qpdf --split-pages "input.pdf" "output_%s.pdf"

Splits each of the page into a pdf


qpdf --pages "input.pdf" 1-5 -- "input.pdf" "range_1_to_5.pdf"

Splits only selected no of pages in a pdf. In both places write the name of the original file in input.pdf


qpdf --empty --pages "input.pdf" 2-5,7-10,12-16 -- "combined_selection.pdf"

Want to select pages in any order use this 
