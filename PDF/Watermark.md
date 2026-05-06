pkg install imagemagick
pkg install qpdf

magick -size 1000x1400 xc:none -gravity Center -pointsize 160 -fill "rgba(128,128,128,0.3)" -draw "rotate -45 text 0,0 'WATERMARK'" stamp.pdf

qpdf "input.pdf" --overlay stamp.pdf --repeat=1 -- Final_Result.pdf



Write the watermark in place of WATERMARK 


For Indian language :

Check which fonts are available in your system:

fc-list :lang=kn  # For Kannada
fc-list :lang=hi  # For Hindi

Once you have a font name (e.g., NotoSansKannada-Regular), add it to your command:


magick -size 1000x1400 xc:none -font "Noto-Sans-Kannada-Regular" -gravity Center -pointsize 150 -fill "rgba(128,128,128,0.3)" -draw "rotate -45 text 0,0 'ಚಿಹ್ನೆ'" stamp.pdf

Write the watermark in place of 
ಚಿಹ್ನೆ

qpdf "input.pdf" --overlay stamp.pdf --repeat=1 -- Final_Result.pdf

