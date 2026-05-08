#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
#                     PDF TOOLS - Termux
# ============================================================

DOWNLOAD_DIR="/sdcard/Download"
if [ ! -d "$DOWNLOAD_DIR" ]; then
    DOWNLOAD_DIR="/storage/emulated/0/Download"
fi

# ── DEPENDENCY CHECKER ───────────────────────────────────────

check_deps() {
    clear
    echo "================================"
    echo "    Checking Dependencies..."
    echo "================================"
    echo ""

    ALL_OK=true

    if command -v qpdf &>/dev/null; then
        echo "  qpdf        ✓"
    else
        echo "  qpdf        ✗  →  pkg install qpdf"
        ALL_OK=false
    fi

    if command -v pdfinfo &>/dev/null; then
        echo "  poppler     ✓"
    else
        echo "  poppler     ✗  →  pkg install poppler   (needed for PDF→Image)"
        ALL_OK=false
    fi

    if python3 -c "import pypdf" &>/dev/null; then
        echo "  pypdf       ✓"
    else
        echo "  pypdf       ✗  →  pip install pypdf"
        ALL_OK=false
    fi

    if python3 -c "from PIL import Image" &>/dev/null; then
        echo "  pillow      ✓"
    else
        echo "  pillow      ✗  →  pip install pillow    (needed for Image→PDF)"
        ALL_OK=false
    fi

    if python3 -c "import pdf2image" &>/dev/null; then
        echo "  pdf2image   ✓"
    else
        echo "  pdf2image   ✗  →  pip install pdf2image (needed for PDF→Image)"
        ALL_OK=false
    fi

    if command -v gs &>/dev/null; then
        echo "  ghostscript ✓"
    else
        echo "  ghostscript ✗  →  pkg install ghostscript (needed for Compress)"
        ALL_OK=false
    fi

    if python3 -c "import pikepdf; from reportlab.pdfgen import canvas" &>/dev/null; then
        echo "  pikepdf     ✓"
        echo "  reportlab   ✓"
    else
        echo "  pikepdf     ✗  →  pip install pikepdf reportlab (needed for 2-Up)"
        ALL_OK=false
    fi

    if command -v pdftotext &>/dev/null; then
        echo "  pdftotext   ✓"
    else
        echo "  pdftotext   ✗  →  pkg install poppler        (needed for PDF→Text)"
        ALL_OK=false
    fi


    echo ""
    if [ "$ALL_OK" = true ]; then
        echo "  All dependencies installed ✓"
    else
        echo "  Some tools may not work until missing packages are installed."
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# ── HELPERS ──────────────────────────────────────────────────

find_file() {
    find /sdcard /storage/emulated/0 "$HOME" \
        -name "$1" 2>/dev/null | head -n 1
}

find_dir() {
    find /sdcard /storage/emulated/0 "$HOME" \
        -type d -name "$1" 2>/dev/null | head -n 1
}

press_enter() {
    echo ""
    read -p "Press Enter to return to menu..."
}

ask_pdf() {
    read -p "Enter PDF filename: " PDF_NAME
    FOUND_PDF=$(find_file "$PDF_NAME")
    if [ -z "$FOUND_PDF" ]; then
        echo "ERROR: '$PDF_NAME' not found."
        return 1
    fi
    echo "Found: $FOUND_PDF"
    TOTAL_PAGES=$(qpdf --show-npages "$FOUND_PDF" 2>/dev/null)
    [ -n "$TOTAL_PAGES" ] && echo "Total pages: $TOTAL_PAGES"
    return 0
}

ask_outname() {
    read -p "Output PDF name: " OUT_NAME
    [ -z "$OUT_NAME" ] && echo "No name given." && return 1
    [[ "$OUT_NAME" != *.pdf ]] && OUT_NAME="${OUT_NAME}.pdf"
    OUT_PATH="$DOWNLOAD_DIR/$OUT_NAME"
    return 0
}

# ── 1) SPLIT PDF ─────────────────────────────────────────────

split_pdf() {
    clear
    echo "================================"
    echo "         Split PDF"
    echo "================================"
    echo ""
    ask_pdf || { press_enter; return; }

    echo ""
    echo "  1)  Range        — extract pages into one PDF"
    echo "  2)  Single pages — every page saved as its own PDF"
    echo ""
    read -p "Select [1/2]: " SPLIT_MODE

    case "$SPLIT_MODE" in
        1)
            echo ""
            echo "Format: 1-5,7,9-11"
            read -p "Page range: " PAGE_RANGE
            [ -z "$PAGE_RANGE" ] && echo "No range entered." && press_enter && return
            QPDF_RANGE=$(echo "$PAGE_RANGE" | tr ',' ' ')
            echo ""
            ask_outname || { press_enter; return; }
            echo ""
            qpdf "$FOUND_PDF" --pages . $QPDF_RANGE -- "$OUT_PATH" 2>&1
            [ $? -eq 0 ] && echo "✓ Saved to: $OUT_PATH" || echo "ERROR: Check page range."
            ;;
        2)
            BASE=$(basename "$FOUND_PDF" .pdf)
            OUT_FOLDER="$DOWNLOAD_DIR/$BASE"
            mkdir -p "$OUT_FOLDER"
            echo ""
            echo "Splitting into single pages → $OUT_FOLDER/"
            echo ""
python3 - <<PYEOF
from pypdf import PdfReader, PdfWriter
import os
reader = PdfReader("$FOUND_PDF")
total = len(reader.pages)
for i, page in enumerate(reader.pages):
    writer = PdfWriter()
    writer.add_page(page)
    out_path = os.path.join("$OUT_FOLDER", f"page_{i+1}.pdf")
    with open(out_path, "wb") as f:
        writer.write(f)
    print(f"  ✓ page_{i+1}.pdf")
print(f"\n✓ Done! {total} pages saved to: $OUT_FOLDER")
PYEOF
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
    press_enter
}

# ── 2) MERGE PDFs ────────────────────────────────────────────

merge_pdf() {
    clear
    echo "================================"
    echo "         Merge PDFs"
    echo "================================"
    echo ""
    echo "Enter PDF filenames (with .pdf) or a folder name."
    echo "Type 'done' when finished."
    echo ""

    FILES=()
    FOLDER=""
    IS_FOLDER=false

    while true; do
        read -p "File/Folder [$((${#FILES[@]} + 1))]: " ENTRY
        [ -z "$ENTRY" ] && continue
        [ "$ENTRY" = "done" ] && break

        if [[ "$ENTRY" == *.pdf ]]; then
            FOUND=$(find_file "$ENTRY")
            if [ -z "$FOUND" ]; then
                echo "  WARNING: '$ENTRY' not found, skipping."
            else
                echo "  ✓ Found: $FOUND"
                FILES+=("$FOUND")
            fi
        else
            if [ "$IS_FOLDER" = true ]; then
                echo "  Only one folder supported. Ignoring."
                continue
            fi
            FOUND_DIR=$(find_dir "$ENTRY")
            if [ -z "$FOUND_DIR" ]; then
                echo "  WARNING: Folder '$ENTRY' not found."
            else
                echo "  ✓ Found folder: $FOUND_DIR"
                FOLDER="$FOUND_DIR"
                IS_FOLDER=true
                break
            fi
        fi
    done

    MERGE_FILES=()
    if [ "$IS_FOLDER" = true ] && [ -n "$FOLDER" ]; then
        while IFS= read -r -d '' f; do
            MERGE_FILES+=("$f")
        done < <(find "$FOLDER" -maxdepth 1 -name "*.pdf" -print0 | sort -z)
        if [ ${#MERGE_FILES[@]} -lt 2 ]; then
            echo "ERROR: Need at least 2 PDFs in folder. Found: ${#MERGE_FILES[@]}"
            press_enter; return
        fi
        echo ""
        echo "PDFs found (${#MERGE_FILES[@]}):"
        for f in "${MERGE_FILES[@]}"; do echo "  - $(basename "$f")"; done
    else
        MERGE_FILES=("${FILES[@]}")
        if [ ${#MERGE_FILES[@]} -lt 2 ]; then
            echo "ERROR: Need at least 2 PDF files. Got: ${#MERGE_FILES[@]}"
            press_enter; return
        fi
    fi

    echo ""
    ask_outname || { press_enter; return; }

    PYTHON_LIST=""
    for f in "${MERGE_FILES[@]}"; do PYTHON_LIST+="'${f}',"; done
    PYTHON_LIST="[${PYTHON_LIST%,}]"

    echo ""
    echo "Merging ${#MERGE_FILES[@]} PDFs..."

python3 - <<PYEOF
from pypdf import PdfWriter
files = $PYTHON_LIST
writer = PdfWriter()
for f in files:
    try:
        writer.append(f)
        print(f"  + {f.split('/')[-1]}")
    except Exception as e:
        print(f"  ERROR: {f} — {e}")
writer.write("$OUT_PATH")
print(f"\n✓ Saved to: $OUT_PATH")
PYEOF
    press_enter
}

# ── 3) IMAGE TO PDF ──────────────────────────────────────────

img_to_pdf() {
    clear
    echo "================================"
    echo "        Image → PDF"
    echo "================================"
    echo ""
    echo "Enter image filenames (any extension) or a folder name."
    echo "Type 'done' when finished."
    echo ""

    IMG_EXTENSIONS=("jpg" "jpeg" "png" "webp" "bmp" "tiff" "tif" "gif")
    is_img() {
        local ext="${1##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        for e in "${IMG_EXTENSIONS[@]}"; do [ "$ext" = "$e" ] && return 0; done
        return 1
    }

    FILES=()
    FOLDER=""
    IS_FOLDER=false

    while true; do
        read -p "File/Folder [$((${#FILES[@]} + 1))]: " ENTRY
        [ -z "$ENTRY" ] && continue
        [ "$ENTRY" = "done" ] && break

        if is_img "$ENTRY"; then
            FOUND=$(find_file "$ENTRY")
            if [ -z "$FOUND" ]; then
                echo "  WARNING: '$ENTRY' not found, skipping."
            else
                echo "  ✓ Found: $FOUND"
                FILES+=("$FOUND")
            fi
        else
            if [ "$IS_FOLDER" = true ]; then
                echo "  Only one folder supported. Ignoring."
                continue
            fi
            FOUND_DIR=$(find_dir "$ENTRY")
            if [ -z "$FOUND_DIR" ]; then
                echo "  WARNING: Folder '$ENTRY' not found."
            else
                echo "  ✓ Found folder: $FOUND_DIR"
                FOLDER="$FOUND_DIR"
                IS_FOLDER=true
                break
            fi
        fi
    done

    IMG_FILES=()
    if [ "$IS_FOLDER" = true ] && [ -n "$FOLDER" ]; then
        while IFS= read -r -d '' f; do
            IMG_FILES+=("$f")
        done < <(find "$FOLDER" -maxdepth 1 \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
               -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.tiff" \
               -o -iname "*.tif" -o -iname "*.gif" \) -print0 | sort -z)
        if [ ${#IMG_FILES[@]} -eq 0 ]; then
            echo "ERROR: No images found in folder."
            press_enter; return
        fi
        echo ""
        echo "Images found (${#IMG_FILES[@]}):"
        for f in "${IMG_FILES[@]}"; do echo "  - $(basename "$f")"; done
    else
        if [ ${#FILES[@]} -eq 0 ]; then
            echo "ERROR: No images provided."
            press_enter; return
        fi
        IMG_FILES=("${FILES[@]}")
    fi

    echo ""
    echo "  1)  Individual — each image as its own PDF"
    echo "  2)  Combined   — all images into one PDF"
    echo ""
    read -p "Select [1/2]: " IMG_MODE

    PYTHON_LIST=""
    for f in "${IMG_FILES[@]}"; do PYTHON_LIST+="'${f}',"; done
    PYTHON_LIST="[${PYTHON_LIST%,}]"

    case "$IMG_MODE" in
        1)
            echo ""
            echo "Converting individually..."
python3 - <<PYEOF
from PIL import Image
import os
files = $PYTHON_LIST
out_dir = "$DOWNLOAD_DIR"
for img_path in files:
    try:
        img = Image.open(img_path).convert("RGB")
        base = os.path.splitext(os.path.basename(img_path))[0]
        out_path = os.path.join(out_dir, f"{base}.pdf")
        img.save(out_path, "PDF")
        print(f"  ✓ {base}.pdf")
    except Exception as e:
        print(f"  ERROR: {img_path} — {e}")
print(f"\n✓ Done! PDFs saved to: {out_dir}")
PYEOF
            ;;
        2)
            echo ""
            ask_outname || { press_enter; return; }
            echo ""
            echo "Combining all images..."
python3 - <<PYEOF
from PIL import Image
import os
files = $PYTHON_LIST
out_path = "$OUT_PATH"
images = []
for f in files:
    try:
        img = Image.open(f).convert("RGB")
        images.append(img)
        print(f"  + {os.path.basename(f)}")
    except Exception as e:
        print(f"  ERROR: {f} — {e}")
if images:
    images[0].save(out_path, "PDF", save_all=True, append_images=images[1:])
    print(f"\n✓ Saved to: {out_path}")
else:
    print("ERROR: No valid images to combine.")
PYEOF
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
    press_enter
}

# ── 4) PDF TO IMAGE ──────────────────────────────────────────

pdf_to_img() {
    clear
    echo "================================"
    echo "        PDF → Images"
    echo "================================"
    echo ""
    ask_pdf || { press_enter; return; }

    BASE=$(basename "$FOUND_PDF" .pdf)
    OUT_FOLDER="$DOWNLOAD_DIR/$BASE"
    mkdir -p "$OUT_FOLDER"

    echo ""
    echo "  1)  JPG"
    echo "  2)  PNG"
    echo ""
    read -p "Select format [1/2]: " FMT_CHOICE
    case "$FMT_CHOICE" in
        2) FMT="png" ;;
        *) FMT="jpg" ;;
    esac

    echo ""
    echo "Converting pages to $FMT → $OUT_FOLDER/"
    echo ""

python3 - <<PYEOF
from pdf2image import convert_from_path
import os
pdf_path = "$FOUND_PDF"
out_folder = "$OUT_FOLDER"
fmt = "$FMT"
pil_fmt = "JPEG" if fmt == "jpg" else "PNG"
try:
    pages = convert_from_path(pdf_path, dpi=200)
    for i, page in enumerate(pages):
        out_path = os.path.join(out_folder, f"page_{i+1}.{fmt}")
        page.save(out_path, pil_fmt)
        print(f"  ✓ page_{i+1}.{fmt}")
    print(f"\n✓ Done! {len(pages)} images saved to: {out_folder}")
except Exception as e:
    print(f"ERROR: {e}")
    print("Make sure poppler is installed: pkg install poppler")
PYEOF
    press_enter
}

# ── 5) ROTATE PDF ────────────────────────────────────────────

rotate_pdf() {
    clear
    echo "================================"
    echo "         Rotate PDF"
    echo "================================"
    echo ""
    ask_pdf || { press_enter; return; }

    echo ""
    echo "  1)  90° Right  (clockwise)"
    echo "  2)  90° Left   (counter-clockwise)"
    echo "  3)  180°       (upside down)"
    echo ""
    read -p "Select [1/2/3]: " ROT_CHOICE

    case "$ROT_CHOICE" in
        1) DEGREES="+90"  ; LABEL="90° Right"  ;;
        2) DEGREES="-90"  ; LABEL="90° Left"   ;;
        3) DEGREES="+180" ; LABEL="180°"        ;;
        *)
            echo "Invalid option."
            press_enter; return
            ;;
    esac

    echo ""
    ask_outname || { press_enter; return; }

    echo ""
    echo "Rotating $LABEL..."
    qpdf "$FOUND_PDF" --rotate=$DEGREES -- "$OUT_PATH" 2>&1
    [ $? -eq 0 ] && echo "✓ Saved to: $OUT_PATH" || echo "ERROR: Rotation failed."
    press_enter
}

# ── 6) REMOVE PAGES ──────────────────────────────────────────

remove_pages() {
    clear
    echo "================================"
    echo "        Remove Pages"
    echo "================================"
    echo ""
    ask_pdf || { press_enter; return; }

    echo ""
    echo "Enter pages to REMOVE."
    echo "Format: 1-2,3,4-5"
    read -p "Pages to remove: " REMOVE_RANGE
    [ -z "$REMOVE_RANGE" ] && echo "No range entered." && press_enter && return

    echo ""
    ask_outname || { press_enter; return; }

    echo ""
    echo "Removing pages..."

python3 - <<PYEOF
from pypdf import PdfReader, PdfWriter

def parse_ranges(range_str, total):
    pages_to_remove = set()
    for part in range_str.split(','):
        part = part.strip()
        if '-' in part:
            start, end = part.split('-')
            for p in range(int(start), int(end)+1):
                pages_to_remove.add(p)
        else:
            pages_to_remove.add(int(part))
    return pages_to_remove

reader = PdfReader("$FOUND_PDF")
total = len(reader.pages)
to_remove = parse_ranges("$REMOVE_RANGE", total)

invalid = [p for p in to_remove if p < 1 or p > total]
if invalid:
    print(f"ERROR: Pages out of range (1-{total}): {invalid}")
    exit(1)

writer = PdfWriter()
kept = 0
for i, page in enumerate(reader.pages):
    if (i + 1) not in to_remove:
        writer.add_page(page)
        kept += 1

with open("$OUT_PATH", "wb") as f:
    writer.write(f)

print(f"  Removed: {sorted(to_remove)}")
print(f"  Kept:    {kept} of {total} pages")
print(f"\n✓ Saved to: $OUT_PATH")
PYEOF
    press_enter
}

# ── 7) REORDER PAGES ─────────────────────────────────────────

reorder_pages() {
    clear
    echo "================================"
    echo "        Reorder Pages"
    echo "================================"
    echo ""
    ask_pdf || { press_enter; return; }

    echo ""
    echo "Enter ALL page numbers in the new order."
    echo "Example: 3,1,2,5,4  moves page 3 to position 1, etc."
    echo ""
    read -p "New order: " NEW_ORDER
    [ -z "$NEW_ORDER" ] && echo "No order entered." && press_enter && return

    QPDF_ORDER=$(echo "$NEW_ORDER" | tr ',' ' ')

    echo ""
    ask_outname || { press_enter; return; }

    echo ""
    echo "Reordering pages..."
    qpdf "$FOUND_PDF" --pages . $QPDF_ORDER -- "$OUT_PATH" 2>&1
    [ $? -eq 0 ] && echo "✓ Saved to: $OUT_PATH" || echo "ERROR: Check page numbers."
    press_enter
}

# ── 8) LOCK / UNLOCK PDF ─────────────────────────────────────

lock_unlock_pdf() {
    clear
    echo "================================"
    echo "      Lock / Unlock PDF"
    echo "================================"
    echo ""
    echo "  1)  Lock PDF   — add password protection"
    echo "  2)  Unlock PDF — remove password protection"
    echo ""
    read -p "Select [1/2]: " LU_CHOICE

    case "$LU_CHOICE" in
        1)
            clear
            echo "================================"
            echo "          Lock PDF"
            echo "================================"
            echo ""
            ask_pdf || { press_enter; return; }

            echo ""
            read -s -p "Create password: " PDF_PASS
            echo ""
            read -s -p "Confirm password: " PDF_PASS2
            echo ""

            if [ "$PDF_PASS" != "$PDF_PASS2" ]; then
                echo "ERROR: Passwords do not match."
                press_enter; return
            fi
            if [ -z "$PDF_PASS" ]; then
                echo "ERROR: Password cannot be empty."
                press_enter; return
            fi

            echo ""
            ask_outname || { press_enter; return; }

            echo ""
            echo "Locking PDF..."

python3 - <<PYEOF
from pypdf import PdfReader, PdfWriter
reader = PdfReader("$FOUND_PDF")
writer = PdfWriter()
for page in reader.pages:
    writer.add_page(page)
writer.encrypt("$PDF_PASS")
with open("$OUT_PATH", "wb") as f:
    writer.write(f)
print("✓ Saved to: $OUT_PATH")
PYEOF
            ;;
        2)
            clear
            echo "================================"
            echo "         Unlock PDF"
            echo "================================"
            echo ""
            ask_pdf || { press_enter; return; }

            echo ""
            read -s -p "Enter current password: " PDF_PASS
            echo ""

            echo ""
            ask_outname || { press_enter; return; }

            echo ""
            echo "Unlocking PDF..."

python3 - <<PYEOF
from pypdf import PdfReader, PdfWriter
reader = PdfReader("$FOUND_PDF")
if reader.is_encrypted:
    result = reader.decrypt("$PDF_PASS")
    if result == 0:
        print("ERROR: Wrong password.")
        exit(1)
else:
    print("ERROR: This PDF is not encrypted.")
    exit(1)
writer = PdfWriter()
for page in reader.pages:
    writer.add_page(page)
with open("$OUT_PATH", "wb") as f:
    writer.write(f)
print("✓ Unlocked and saved to: $OUT_PATH")
PYEOF
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
    press_enter
}

# ── 9) COMPRESS PDF ──────────────────────────────────────────

compress_pdf() {
    clear
    echo "================================"
    echo "        Compress PDF"
    echo "================================"
    echo ""
    ask_pdf || { press_enter; return; }

    echo ""
    echo "  1)  Low quality    (smallest file)"
    echo "  2)  Medium quality (balanced)"
    echo "  3)  High quality   (best quality)"
    echo ""
    read -p "Select [1/2/3]: " QUAL_CHOICE

    case "$QUAL_CHOICE" in
        1) SETTING="/screen"  ; LABEL="Low"    ;;
        2) SETTING="/ebook"   ; LABEL="Medium" ;;
        3) SETTING="/printer" ; LABEL="High"   ;;
        *)
            echo "Invalid option."
            press_enter; return
            ;;
    esac

    echo ""
    ask_outname || { press_enter; return; }

    echo ""
    echo "Compressing at $LABEL quality..."
    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=$SETTING \
       -dNOPAUSE -dQUIET -dBATCH \
       -sOutputFile="$OUT_PATH" \
       "$FOUND_PDF" 2>&1

    if [ $? -eq 0 ]; then
        ORIG=$(du -k "$FOUND_PDF" | cut -f1)
        NEW=$(du -k "$OUT_PATH" | cut -f1)
        echo "✓ Done!"
        echo "  Original:   ${ORIG} KB"
        echo "  Compressed: ${NEW} KB"
        echo "  Saved to:   $OUT_PATH"
    else
        echo "ERROR: Compression failed. Is ghostscript installed? (pkg install ghostscript)"
    fi
    press_enter
}


# ── 10) 2-UP (2 PAGES PER SHEET) ─────────────────────────────

two_up_pdf() {
    clear
    echo "================================"
    echo "      2 Pages Per Sheet"
    echo "================================"
    echo ""
    ask_pdf || { press_enter; return; }

    echo ""
    echo "Enter outer and inner margins in mm."
    echo "Format: outer,inner   (e.g. 0,0 or 5,3)"
    echo "  Outer = margin around the outside edges"
    echo "  Inner = margin between the two pages"
    read -p "Margins (outer,inner): " MARGINS

    if [ -z "$MARGINS" ]; then
        MARGINS="0,0"
    fi

    OUTER_MM=$(echo "$MARGINS" | cut -d',' -f1 | tr -d ' ')
    INNER_MM=$(echo "$MARGINS" | cut -d',' -f2 | tr -d ' ')

    if ! [[ "$OUTER_MM" =~ ^[0-9]+([.][0-9]+)?$ ]] || ! [[ "$INNER_MM" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "ERROR: Invalid margin format. Use numbers like 0,0 or 5,3"
        press_enter; return
    fi

    echo ""
    ask_outname || { press_enter; return; }

    echo ""
    echo "Detecting orientation and building 2-up A4 layout..."
    echo ""

    PYFILE=$HOME/twoup_$$.py
    cat > "$PYFILE" << 'ENDOFPY'
import sys, os, tempfile, shutil
from pypdf import PdfReader, PdfWriter
from reportlab.lib.units import mm
from reportlab.lib.pagesizes import A4
import pikepdf

pdf_path = sys.argv[1]
out_path = sys.argv[2]
outer_pt = float(sys.argv[3]) * mm
inner_pt = float(sys.argv[4]) * mm

A4_W, A4_H = A4
reader = PdfReader(pdf_path)
total = len(reader.pages)
if total == 0:
    print("ERROR: PDF has no pages.")
    sys.exit(1)

first = reader.pages[0]
w_pt = float(first.mediabox.width)
h_pt = float(first.mediabox.height)
is_landscape = w_pt > h_pt

print("  Detected: " + ("Landscape" if is_landscape else "Portrait") + " pages (" + str(round(w_pt)) + " x " + str(round(h_pt)) + " pt)")
print("  Total pages: " + str(total))
print("  Output: A4 sheets")
print("")

tmp_dir = tempfile.mkdtemp()
page_files = []
for i in range(total):
    w = PdfWriter()
    w.add_page(reader.pages[i])
    p = os.path.join(tmp_dir, "p" + str(i) + ".pdf")
    with open(p, "wb") as f:
        w.write(f)
    page_files.append(p)

if not is_landscape:
    sheet_w, sheet_h = A4_H, A4_W
    available_w = sheet_w - outer_pt * 2 - inner_pt
    available_h = sheet_h - outer_pt * 2
    slot_w = available_w / 2
    slot_h = available_h
    scale = min(slot_w / w_pt, slot_h / h_pt)
    pw = w_pt * scale
    ph = h_pt * scale
    def get_pos(slot):
        if slot == 0:
            x = outer_pt + (slot_w - pw) / 2
        else:
            x = outer_pt + slot_w + inner_pt + (slot_w - pw) / 2
        y = outer_pt + (slot_h - ph) / 2
        return x, y
else:
    sheet_w, sheet_h = A4_W, A4_H
    available_w = sheet_w - outer_pt * 2
    available_h = sheet_h - outer_pt * 2 - inner_pt
    slot_w = available_w
    slot_h = available_h / 2
    scale = min(slot_w / w_pt, slot_h / h_pt)
    pw = w_pt * scale
    ph = h_pt * scale
    def get_pos(slot):
        x = outer_pt + (slot_w - pw) / 2
        if slot == 0:
            y = outer_pt + slot_h + inner_pt + (slot_h - ph) / 2
        else:
            y = outer_pt + (slot_h - ph) / 2
        return x, y

out_pdf = pikepdf.Pdf.new()
pairs = (total + 1) // 2

for i in range(pairs):
    xobjects = {}
    stream_parts = []
    for slot in range(2):
        idx = i * 2 + slot
        if idx >= total:
            break
        src_pdf = pikepdf.open(page_files[idx])
        src_page = src_pdf.pages[0]
        mb = src_page.mediabox
        pg_w = float(mb[2]) - float(mb[0])
        pg_h = float(mb[3]) - float(mb[1])
        if "/CropBox" in src_page:
            del src_page["/CropBox"]
        xobj = pikepdf.Page(src_page).as_form_xobject()
        xobj["/BBox"] = pikepdf.Array([0, 0, pg_w, pg_h])
        xname = "Src" + str(slot)
        xobjects[xname] = out_pdf.copy_foreign(xobj)
        x, y = get_pos(slot)
        part = "q " + str(scale) + " 0 0 " + str(scale) + " " + str(x) + " " + str(y) + " cm /" + xname + " Do Q"
        stream_parts.append(part)
        print("  + Page " + str(idx+1) + " -> sheet " + str(i+1) + " pos " + str(slot+1))

    stream_content = b"\n".join(p.encode("latin-1") for p in stream_parts)
    new_page = pikepdf.Dictionary(
        Type=pikepdf.Name("/Page"),
        MediaBox=pikepdf.Array([0, 0, sheet_w, sheet_h]),
        Resources=pikepdf.Dictionary(XObject=pikepdf.Dictionary(**xobjects)),
        Contents=pikepdf.Stream(out_pdf, stream_content)
    )
    out_pdf.pages.append(pikepdf.Page(new_page))

out_pdf.save(out_path)
shutil.rmtree(tmp_dir)
print("")
print("Done! " + str(pairs) + " A4 sheet(s) saved to: " + out_path)
ENDOFPY

    python3 "$PYFILE" "$FOUND_PDF" "$OUT_PATH" "$OUTER_MM" "$INNER_MM"
    rm -f "$PYFILE"
    press_enter
}


# ── 11) PDF TO TEXT ───────────────────────────────────────────

pdf_to_text() {
    clear
    echo "================================"
    echo "         PDF to Text"
    echo "================================"
    echo ""
    ask_pdf || { press_enter; return; }

    echo ""
    echo "  1)  Save as .txt file"
    echo "  2)  View text on screen"
    echo ""
    read -p "Select [1/2]: " TXT_MODE

    case "$TXT_MODE" in
        1)
            BASE=$(basename "$FOUND_PDF" .pdf)
            OUT_TXT="$DOWNLOAD_DIR/${BASE}.txt"
            echo ""
            echo "Extracting text..."
            pdftotext "$FOUND_PDF" "$OUT_TXT" 2>&1
            if [ $? -eq 0 ]; then
                echo "✓ Saved to: $OUT_TXT"
            else
                echo "ERROR: pdftotext failed. Is poppler installed? (pkg install poppler)"
            fi
            ;;
        2)
            echo ""
            echo "Extracting text..."
            TMPFILE=$HOME/pdftxt_$$.txt
            pdftotext "$FOUND_PDF" "$TMPFILE" 2>&1
            if [ $? -eq 0 ]; then
                echo "Scroll with arrow keys. Press q to exit."
                echo ""
                sleep 1
                less "$TMPFILE"
            else
                echo "ERROR: pdftotext failed. Is poppler installed? (pkg install poppler)"
            fi
            rm -f "$TMPFILE"
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
    press_enter
}

# ── MAIN MENU ────────────────────────────────────────────────

check_deps

while true; do
    clear
    echo "================================"
    echo "         PDF Tools"
    echo "================================"
    echo ""
    echo "  1)  Split PDF"
    echo "  2)  Merge PDFs"
    echo "  3)  Image → PDF"
    echo "  4)  PDF → Image"
    echo "  5)  Rotate PDF"
    echo "  6)  Remove Pages"
    echo "  7)  Reorder Pages"
    echo "  8)  Lock / Unlock PDF"
    echo "  9)  Compress PDF"
    echo " 10)  2 Pages Per Sheet"
    echo " 11)  PDF to Text"
    echo ""
    echo "  0)  Exit"
    echo ""
    read -p "Select option: " CHOICE

    case "$CHOICE" in
        1) split_pdf      ;;
        2) merge_pdf      ;;
        3) img_to_pdf     ;;
        4) pdf_to_img     ;;
        5) rotate_pdf     ;;
        6) remove_pages   ;;
        7) reorder_pages  ;;
        8) lock_unlock_pdf;;
        9) compress_pdf   ;;
       10) two_up_pdf    ;;
       11) pdf_to_text  ;;
        0) echo ""; echo "Bye!"; exit 0 ;;
        *) echo "Invalid option."; sleep 1 ;;
    esac
done
