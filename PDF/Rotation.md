pkg install qpdf


qpdf "input.pdf" --rotate=ANGLE:1-z -- "output.pdf"

Replace ANGLE with your desired multiple of 90:
90: Clockwise (Landscape Right)
180: Upside Down
270: Counter-clockwise (Landscape Left)
0: Original Orientation


