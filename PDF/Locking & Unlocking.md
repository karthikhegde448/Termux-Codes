Locking

pip install pypdf

python -c "from pypdf import PdfReader, PdfWriter; reader = PdfReader('/sdcard/Download/final.pdf'); writer = PdfWriter(); writer.append_pages_from_reader(reader); writer.encrypt('your_password_here'); [writer.write(f) for f in [open('/sdcard/Download/final_locked.pdf', 'wb')]]"

Change final.pdf to name.pdf to work

Unlocking

pkg install qpdf

qpdf --decrypt --password="your_password" "locked_file.pdf" "unlocked_output.pdf"

Rename the locked_file.pdf as the original PDF name and write password in place of your_password

Unlocking many pdfs at one time
Only when all have same password


for file in *.pdf; do qpdf --decrypt --password="YOUR_PASS" "$file" "unlocked_$file"; done

Just replace YOUR_PASS by password and keep the files in a single folder
