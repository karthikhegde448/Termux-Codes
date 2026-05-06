pkg install ghostscript

/screen (Low Quality)
/ebook (Medium Quality)
/printer (High Quality)

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile="compressed.pdf" "input.pdf" 

Change the name of input.pdf to original file 
