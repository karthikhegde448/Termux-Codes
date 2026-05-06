pkg install python-pillow
pip install pypdf


python -c "from PIL import Image; import os; p='/sdcard/Download/trial'; out='/sdcard/Download/final.pdf'; imgs=[Image.open(os.path.join(p, f)).convert('RGB') for f in sorted(os.listdir(p)) if f.lower().endswith(('.jpg','.png','.jpeg'))]; imgs[0].save(out, save_all=True, append_images=imgs[1:]) if imgs else print('No images found')"

Write in place of trial the folder name keep every image in the same folder 



To convert multiple images into individual PDFs (one PDF per image) within a folder

pkg install imagemagick

for f in *.jpg; do magick "$f" "${f%.jpg}.pdf"; done


For png, change .jpg to .png
