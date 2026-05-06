pip install pypdf

For files without folder

python -c "from pypdf import PdfWriter; writer = PdfWriter(); [writer.append(f'/sdcard/Download/{f}') for f in ['file1.pdf', 'file2.pdf']]; writer.write('/sdcard/Download/merged_output.pdf')"


For a folder


python -c "import os; from pypdf import PdfWriter; writer = PdfWriter(); path='/sdcard/Download/my_pdfs'; files=sorted([f for f in os.listdir(path) if f.endswith('.pdf')]); [writer.append(os.path.join(path, f)) for f in files]; writer.write('/sdcard/Download/all_combined.pdf')"



Change my_pdfs to the folder name to work
