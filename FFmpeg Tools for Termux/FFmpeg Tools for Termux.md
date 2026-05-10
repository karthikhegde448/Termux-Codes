# 🎬 FFmpeg Tools for Termux

A powerful, menu-driven **audio & video toolkit** for Termux on Android, built on top of FFmpeg.
No commands to memorize — just pick a tool and follow the prompts.

---

## 📦 Step 1 — Install Packages

Open **Termux** and run these commands one by one:

```bash
pkg update -y && pkg upgrade -y
```

```bash
pkg install ffmpeg -y
```

```bash
pkg install nano -y
```

```bash
termux-setup-storage
```

> When prompted, tap **Allow** to give Termux access to your phone's storage.
> This is required so the script can find and save your files.

---

## 📝 Step 2 — Create the Script File

Run this to open the nano editor:

```bash
nano ffmpeg_tools.sh
```

Then **paste the entire script below** into nano:

```bash
#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
#  FFmpeg Tools for Termux
#  A handy audio/video toolkit powered by FFmpeg
# ============================================================

# ---------- Colors & Styles ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ---------- Banner ----------
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ███████╗███████╗███╗   ███╗██████╗ ███████╗ ██████╗"
    echo "  ██╔════╝██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝"
    echo "  █████╗  █████╗  ██╔████╔██║██████╔╝█████╗  ██║  ███╗"
    echo "  ██╔══╝  ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██╔══╝  ██║   ██║"
    echo "  ██║     ██║     ██║ ╚═╝ ██║██║     ███████╗╚██████╔╝"
    echo "  ╚═╝     ╚═╝     ╚═╝     ╚═╝╚═╝     ╚══════╝ ╚═════╝ "
    echo -e "${WHITE}              T O O L S   F O R   T E R M U X${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo -e "${DIM}  Powered by FFmpeg  |  Audio & Video Swiss Army Knife${RESET}"
    echo ""
}

# ---------- Dependency Check ----------
check_ffmpeg() {
    if ! command -v ffmpeg &>/dev/null; then
        echo -e "${YELLOW}⚠  FFmpeg not found. Installing...${RESET}"
        pkg install ffmpeg -y
        if ! command -v ffmpeg &>/dev/null; then
            echo -e "${RED}✗  FFmpeg installation failed. Please run: pkg install ffmpeg${RESET}"
            exit 1
        fi
        echo -e "${GREEN}✓  FFmpeg installed successfully!${RESET}"
    fi
}

# ---------- Press any key ----------
pause() {
    echo ""
    echo -e "${DIM}  Press [Enter] to continue...${RESET}"
    read -r
}

# ---------- File Finder ----------
# Usage: find_file "filename.ext"
# Returns full path or empty string
find_file() {
    local fname="$1"
    local found
    # Search common Termux-accessible storage locations
    found=$(find /storage/emulated/0 \
                 /sdcard \
                 "$HOME" \
                 2>/dev/null \
                 -type f -name "$fname" \
                 -print -quit 2>/dev/null)
    echo "$found"
}

# ---------- Parse comma-separated filenames ----------
# Usage: parse_filenames "1.mp3, 2.opus, 3.mp3"
# Populates global array FILE_PATHS and FILE_EXTS
FILE_PATHS=()
FILE_EXTS=()

parse_and_find_files() {
    local raw_input="$1"
    FILE_PATHS=()
    FILE_EXTS=()

    # Split by comma
    IFS=',' read -ra parts <<< "$raw_input"
    local all_found=true

    for part in "${parts[@]}"; do
        local name
        name=$(echo "$part" | xargs)  # trim whitespace
        if [[ -z "$name" ]]; then continue; fi

        echo -e "  ${DIM}Searching for: ${YELLOW}${name}${RESET}"
        local path
        path=$(find_file "$name")

        if [[ -z "$path" ]]; then
            echo -e "  ${RED}✗  Not found: $name${RESET}"
            all_found=false
        else
            echo -e "  ${GREEN}✓  Found: $path${RESET}"
            FILE_PATHS+=("$path")
            # Extract extension (lowercase)
            local ext="${name##*.}"
            FILE_EXTS+=("${ext,,}")
        fi
    done

    if [[ "$all_found" == false ]]; then
        return 1
    fi
    return 0
}

# ============================================================
#  AUDIO TOOLS
# ============================================================

# ── Audio: Merge ─────────────────────────────────────────────
audio_merge() {
    show_banner
    echo -e "${MAGENTA}  ♪  AUDIO › MERGE FILES${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Enter filenames separated by commas."
    echo -e "  ${DIM}Example: 1.mp3, 2.opus, chorus.mp3${RESET}"
    echo ""
    echo -ne "  ${CYAN}Files to merge: ${RESET}"
    read -r user_input

    if [[ -z "$user_input" ]]; then
        echo -e "${RED}  ✗  No input provided.${RESET}"
        pause; return
    fi

    echo ""
    echo -e "  ${YELLOW}⟳  Locating files on device...${RESET}"
    echo ""

    parse_and_find_files "$user_input"
    local status=$?

    if [[ $status -ne 0 ]]; then
        echo ""
        echo -e "  ${RED}✗  One or more files could not be found.${RESET}"
        echo -e "  ${DIM}  Make sure storage permission is granted:${RESET}"
        echo -e "  ${DIM}  termux-setup-storage${RESET}"
        pause; return
    fi

    if [[ ${#FILE_PATHS[@]} -lt 2 ]]; then
        echo -e "  ${RED}✗  Please provide at least 2 files to merge.${RESET}"
        pause; return
    fi

    echo ""
    echo -ne "  ${CYAN}Output filename (e.g. merged.mp3): ${RESET}"
    read -r out_name

    if [[ -z "$out_name" ]]; then
        echo -e "  ${RED}✗  No output name provided.${RESET}"
        pause; return
    fi

    # Determine output directory — same as first file's directory
    local out_dir
    out_dir=$(dirname "${FILE_PATHS[0]}")
    local out_path="${out_dir}/${out_name}"

    # Build a temporary concat list file
    local list_file
    list_file=$(mktemp /tmp/ffmpeg_concat_XXXXXX.txt)

    for f in "${FILE_PATHS[@]}"; do
        echo "file '${f}'" >> "$list_file"
    done

    echo ""
    echo -e "  ${YELLOW}⟳  Merging ${#FILE_PATHS[@]} files...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    ffmpeg -f concat -safe 0 -i "$list_file" -c copy "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    rm -f "$list_file"

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo ""
        echo -e "  ${GREEN}✓  Merge complete!${RESET}"
        echo -e "  ${GREEN}   Saved: ${out_path} (${size})${RESET}"
    else
        echo ""
        echo -e "  ${RED}✗  Merge failed. Check file formats are compatible.${RESET}"
        echo -e "  ${DIM}  Tip: All files should be the same format (e.g. all .mp3)${RESET}"
        echo -e "  ${DIM}  For mixed formats, use option 5 (Convert Format) first.${RESET}"
    fi

    pause
}

# ── Audio: Trim ──────────────────────────────────────────────
audio_trim() {
    show_banner
    echo -e "${MAGENTA}  ♪  AUDIO › TRIM / CUT${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Cuts a portion from your audio file."
    echo -e "  ${DIM}You set a start time and how long the clip should be.${RESET}"
    echo ""

    # Input file
    echo -ne "  ${CYAN}Input filename (e.g. song.mp3): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    echo ""
    echo -e "  ${DIM}Time format: HH:MM:SS  (e.g. 00:01:30 = 1 minute 30 seconds)${RESET}"
    echo ""

    # Start time
    echo -ne "  ${CYAN}Start time (e.g. 00:00:30): ${RESET}"
    read -r start_time
    if [[ -z "$start_time" ]]; then echo -e "  ${RED}✗  No start time given.${RESET}"; pause; return; fi

    # Duration
    echo -ne "  ${CYAN}Duration to keep (e.g. 00:00:10): ${RESET}"
    read -r duration
    if [[ -z "$duration" ]]; then echo -e "  ${RED}✗  No duration given.${RESET}"; pause; return; fi

    # Output
    echo -ne "  ${CYAN}Output filename (e.g. trimmed.mp3): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Trimming audio...${RESET}"
    echo -e "  ${DIM}  Start: ${start_time}  |  Duration: ${duration}${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    ffmpeg -i "$in_path" -ss "$start_time" -t "$duration" -c copy "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Trim complete! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Trim failed. Check your time format (HH:MM:SS).${RESET}"
    fi

    pause
}

# ── Audio: Speed ─────────────────────────────────────────────
audio_speed() {
    show_banner
    echo -e "${MAGENTA}  ♪  AUDIO › CHANGE SPEED${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Changes playback speed without changing pitch."
    echo -e "  ${DIM}Speed examples:${RESET}"
    echo -e "  ${DIM}   0.5 = half speed (slower)${RESET}"
    echo -e "  ${DIM}   1.0 = original speed${RESET}"
    echo -e "  ${DIM}   1.5 = 1.5x faster${RESET}"
    echo -e "  ${DIM}   2.0 = double speed${RESET}"
    echo -e "  ${DIM}  (Valid range: 0.5 to 100.0)${RESET}"
    echo ""

    # Input file
    echo -ne "  ${CYAN}Input filename (e.g. song.mp3): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    echo ""
    echo -ne "  ${CYAN}Speed multiplier (e.g. 2.0): ${RESET}"
    read -r speed
    if [[ -z "$speed" ]]; then echo -e "  ${RED}✗  No speed value given.${RESET}"; pause; return; fi

    # Validate: must be a number between 0.5 and 100
    if ! echo "$speed" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
        echo -e "  ${RED}✗  Invalid speed value. Use a number like 1.5 or 2.0${RESET}"
        pause; return
    fi

    echo -ne "  ${CYAN}Output filename (e.g. fast_audio.mp3): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Adjusting speed to ${speed}x...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    # Note: atempo only accepts 0.5–2.0; for >2.0 we chain filters
    # Build the atempo chain dynamically
    local atempo_filter=""
    local remaining
    remaining=$(echo "$speed" | awk '{printf "%.6f", $1}')

    # Chain atempo filters: each handles max 2.0x or min 0.5x
    while true; do
        local val
        # If remaining > 2.0, apply 2.0 and divide
        if awk "BEGIN{exit !($remaining > 2.0)}"; then
            val="2.0"
            remaining=$(awk "BEGIN{printf \"%.6f\", $remaining / 2.0}")
        # If remaining < 0.5, apply 0.5 and multiply
        elif awk "BEGIN{exit !($remaining < 0.5)}"; then
            val="0.5"
            remaining=$(awk "BEGIN{printf \"%.6f\", $remaining / 0.5}")
        else
            val="$remaining"
            remaining="1.0"
        fi

        if [[ -z "$atempo_filter" ]]; then
            atempo_filter="atempo=${val}"
        else
            atempo_filter="${atempo_filter},atempo=${val}"
        fi

        if awk "BEGIN{exit !(${remaining} == 1.0 || ${remaining} >= 0.9999 && ${remaining} <= 1.0001)}"; then
            break
        fi
    done

    ffmpeg -i "$in_path" -filter:a "$atempo_filter" -vn "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Speed change complete! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Failed. Ensure speed is between 0.5 and 100.0${RESET}"
    fi

    pause
}

# ── Audio: Silencer (Insert Silence) ─────────────────────────
audio_silencer() {
    show_banner
    echo -e "${MAGENTA}  ♪  AUDIO › INSERT SILENCE${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Inserts a gap of silence at a chosen point in your audio."
    echo ""
    echo -e "  ${DIM}How it works:${RESET}"
    echo -e "  ${DIM}  • You pick a split point (in seconds) — e.g. 10${RESET}"
    echo -e "  ${DIM}  • Audio plays until that point, then silence is added,${RESET}"
    echo -e "  ${DIM}    then the rest of the audio continues after the gap.${RESET}"
    echo ""

    # Input file
    echo -ne "  ${CYAN}Input filename (e.g. song.mp3): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"
    echo ""

    # Split point
    echo -e "  ${DIM}Enter the second-mark where silence should be inserted.${RESET}"
    echo -e "  ${DIM}Example: 10 means silence is injected at the 10-second mark.${RESET}"
    echo -ne "  ${CYAN}Split point (seconds, e.g. 10): ${RESET}"
    read -r split_sec
    if [[ -z "$split_sec" ]]; then echo -e "  ${RED}✗  No split point given.${RESET}"; pause; return; fi

    if ! echo "$split_sec" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
        echo -e "  ${RED}✗  Invalid value. Enter a number like 10 or 45.5${RESET}"
        pause; return
    fi

    # Gap duration
    echo -ne "  ${CYAN}Silence duration (seconds, e.g. 5): ${RESET}"
    read -r gap_sec
    if [[ -z "$gap_sec" ]]; then echo -e "  ${RED}✗  No gap duration given.${RESET}"; pause; return; fi

    if ! echo "$gap_sec" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
        echo -e "  ${RED}✗  Invalid value. Enter a number like 5 or 2.5${RESET}"
        pause; return
    fi

    # Output
    echo -ne "  ${CYAN}Output filename (e.g. output.mp3): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Inserting ${gap_sec}s of silence at ${split_sec}s mark...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    # Detect sample rate from input for anullsrc (default 44100)
    local sample_rate
    sample_rate=$(ffprobe -v error -select_streams a:0 \
        -show_entries stream=sample_rate \
        -of default=noprint_wrappers=1:nokey=1 "$in_path" 2>/dev/null)
    sample_rate="${sample_rate:-44100}"

    ffmpeg -i "$in_path" -filter_complex \
        "anullsrc=r=${sample_rate}:cl=stereo:d=${gap_sec}[silence];
         [0:a]atrim=end=${split_sec}[part1];
         [0:a]atrim=start=${split_sec}[part2];
         [part1][silence][part2]concat=n=3:v=0:a=1" \
        "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Done! Silence inserted. Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Failed. Make sure the split point is within the audio duration.${RESET}"
    fi

    pause
}

# ── Audio: Convert Format ────────────────────────────────────
audio_convert() {
    show_banner
    echo -e "${MAGENTA}  ♪  AUDIO › CONVERT FORMAT${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Converts an audio file from one format to another."
    echo -e "  ${DIM}Supported formats: mp3, opus, aac, flac, wav, ogg, m4a, wma${RESET}"
    echo ""

    # Input file
    echo -ne "  ${CYAN}Input filename (e.g. song.mp3): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"
    echo ""

    # Output filename — user must include the new extension
    echo -e "  ${DIM}Include the new extension in the output name.${RESET}"
    echo -e "  ${DIM}Example: converted.opus  or  output.aac${RESET}"
    echo -ne "  ${CYAN}Output filename (e.g. converted.opus): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    # Detect target format from extension for codec hints
    local out_ext="${out_name##*.}"
    out_ext="${out_ext,,}"

    # Pick sensible default codec args per format
    local codec_args=""
    case "$out_ext" in
        opus)  codec_args="-c:a libopus -b:a 128k" ;;
        mp3)   codec_args="-c:a libmp3lame -q:a 2" ;;
        aac|m4a) codec_args="-c:a aac -b:a 128k" ;;
        flac)  codec_args="-c:a flac" ;;
        wav)   codec_args="-c:a pcm_s16le" ;;
        ogg)   codec_args="-c:a libvorbis -q:a 4" ;;
        wma)   codec_args="-c:a wmav2 -b:a 128k" ;;
        *)     codec_args="-c:a copy" ;;
    esac

    echo ""
    echo -e "  ${YELLOW}⟳  Converting to ${out_ext^^}...${RESET}"
    echo -e "  ${DIM}  ${in_path}${RESET}"
    echo -e "  ${DIM}  → ${out_path}${RESET}"
    echo ""

    ffmpeg -i "$in_path" $codec_args "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Conversion complete! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Conversion failed. The input format may not be compatible.${RESET}"
        echo -e "  ${DIM}  Try: ffmpeg -i \"${in_name}\" to see stream details.${RESET}"
    fi

    pause
}

# ── Audio: Extract Audio from Video ──────────────────────────
audio_extract() {
    show_banner
    echo -e "${MAGENTA}  ♪  AUDIO › EXTRACT FROM VIDEO${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Pulls the audio track out of a video file."
    echo -e "  ${DIM}Works with: mp4, mkv, avi, mov, webm, flv, etc.${RESET}"
    echo ""

    # Input video file
    echo -ne "  ${CYAN}Video filename (e.g. video.mp4): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    # Show detected audio stream info
    echo ""
    echo -e "  ${DIM}Detected audio stream:${RESET}"
    local stream_info
    stream_info=$(ffprobe -v error -select_streams a:0 \
        -show_entries stream=codec_name,bit_rate,sample_rate,channels \
        -of default=noprint_wrappers=1 "$in_path" 2>/dev/null)
    if [[ -n "$stream_info" ]]; then
        echo "$stream_info" | while IFS= read -r line; do
            echo -e "  ${DIM}  ${line}${RESET}"
        done
    else
        echo -e "  ${DIM}  (could not detect stream info)${RESET}"
    fi
    echo ""

    # Output filename
    echo -e "  ${DIM}Include the desired audio extension in the output name.${RESET}"
    echo -e "  ${DIM}Example: audio.mp3  or  extracted.opus${RESET}"
    echo -ne "  ${CYAN}Output filename (e.g. audio.mp3): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    local out_ext="${out_name##*.}"
    out_ext="${out_ext,,}"

    # Codec args for output format
    local codec_args=""
    case "$out_ext" in
        opus)    codec_args="-c:a libopus -b:a 128k" ;;
        mp3)     codec_args="-c:a libmp3lame -q:a 2" ;;
        aac|m4a) codec_args="-c:a aac -b:a 128k" ;;
        flac)    codec_args="-c:a flac" ;;
        wav)     codec_args="-c:a pcm_s16le" ;;
        ogg)     codec_args="-c:a libvorbis -q:a 4" ;;
        *)       codec_args="-c:a copy" ;;   # try lossless copy
    esac

    echo ""
    echo -e "  ${YELLOW}⟳  Extracting audio track...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    ffmpeg -i "$in_path" -vn $codec_args "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Extracted! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Extraction failed. Make sure the video has an audio track.${RESET}"
    fi

    pause
}

# ── Audio: Adjust Volume ──────────────────────────────────────
audio_volume() {
    show_banner
    echo -e "${MAGENTA}  ♪  AUDIO › ADJUST VOLUME${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Changes the volume of an audio file in decibels (dB)."
    echo ""

    # Input file
    echo -ne "  ${CYAN}Input filename (e.g. song.mp3): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    # Detect current volume (mean & max dB via volumedetect)
    echo ""
    echo -e "  ${YELLOW}⟳  Analysing current volume levels...${RESET}"
    local vol_info
    vol_info=$(ffmpeg -i "$in_path" -af volumedetect -f null /dev/null 2>&1 | \
               grep -E "mean_volume|max_volume")

    local mean_vol max_vol
    mean_vol=$(echo "$vol_info" | grep "mean_volume" | awk '{print $5, $6}')
    max_vol=$(echo  "$vol_info" | grep "max_volume"  | awk '{print $5, $6}')

    echo ""
    echo -e "  ${WHITE}┌─ Current Volume Levels ──────────────────────┐${RESET}"
    if [[ -n "$mean_vol" ]]; then
        echo -e "  ${WHITE}│${RESET}  Mean (average) volume : ${CYAN}${mean_vol}${RESET}"
        echo -e "  ${WHITE}│${RESET}  Max  (peak)    volume : ${CYAN}${max_vol}${RESET}"
    else
        echo -e "  ${WHITE}│${RESET}  ${DIM}(Could not detect volume — file may be unusual)${RESET}"
    fi
    echo -e "  ${WHITE}└──────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${DIM}Enter the new volume level in dB.${RESET}"
    echo -e "  ${DIM}Examples:${RESET}"
    echo -e "  ${DIM}   -5 dB  → quieter${RESET}"
    echo -e "  ${DIM}    0 dB  → no change${RESET}"
    echo -e "  ${DIM}   +5 dB  → louder  (type: 5 or +5)${RESET}"
    echo -e "  ${DIM}  Tip: keep max volume below 0 dB to avoid clipping.${RESET}"
    echo ""
    echo -ne "  ${CYAN}New volume level in dB (e.g. -3 or 5): ${RESET}"
    read -r new_vol

    if [[ -z "$new_vol" ]]; then echo -e "  ${RED}✗  No value given.${RESET}"; pause; return; fi

    # Validate: allow optional leading + or -, digits, optional decimal
    if ! echo "$new_vol" | grep -qE '^[+-]?[0-9]+(\.[0-9]+)?$'; then
        echo -e "  ${RED}✗  Invalid value. Enter a number like -5, 0, or 10${RESET}"
        pause; return
    fi

    # Output filename
    echo -ne "  ${CYAN}Output filename (e.g. louder.mp3): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Applying ${new_vol} dB volume change...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    ffmpeg -i "$in_path" -af "volume=${new_vol}dB" "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Volume adjusted! Saved: ${out_path} (${size})${RESET}"

        # Show new volume levels
        echo ""
        echo -e "  ${YELLOW}⟳  Verifying new volume levels...${RESET}"
        local new_vol_info
        new_vol_info=$(ffmpeg -i "$out_path" -af volumedetect -f null /dev/null 2>&1 | \
                       grep -E "mean_volume|max_volume")
        local new_mean new_max
        new_mean=$(echo "$new_vol_info" | grep "mean_volume" | awk '{print $5, $6}')
        new_max=$(echo  "$new_vol_info" | grep "max_volume"  | awk '{print $5, $6}')
        if [[ -n "$new_mean" ]]; then
            echo -e "  ${WHITE}┌─ New Volume Levels ───────────────────────────┐${RESET}"
            echo -e "  ${WHITE}│${RESET}  Mean volume : ${GREEN}${new_mean}${RESET}"
            echo -e "  ${WHITE}│${RESET}  Max  volume : ${GREEN}${new_max}${RESET}"
            echo -e "  ${WHITE}└──────────────────────────────────────────────┘${RESET}"
        fi
    else
        echo -e "  ${RED}✗  Failed. Check that the input file is a valid audio file.${RESET}"
    fi

    pause
}

# ── Audio: Adjust Pitch ──────────────────────────────────────
audio_pitch() {
    show_banner
    echo -e "${MAGENTA}  ♪  AUDIO › ADJUST PITCH${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Changes the pitch of audio without affecting its length."
    echo ""
    echo -e "  ${DIM}Pitch factor examples:${RESET}"
    echo -e "  ${DIM}   0.5  → one octave lower (deeper)${RESET}"
    echo -e "  ${DIM}   0.75 → slightly lower${RESET}"
    echo -e "  ${DIM}   1.0  → no change (original)${RESET}"
    echo -e "  ${DIM}   1.25 → slightly higher${RESET}"
    echo -e "  ${DIM}   1.5  → noticeably higher${RESET}"
    echo -e "  ${DIM}   2.0  → one octave higher${RESET}"
    echo ""

    # Input file
    echo -ne "  ${CYAN}Input filename (e.g. song.mp3): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    # Detect sample rate
    local sample_rate
    sample_rate=$(ffprobe -v error -select_streams a:0 \
        -show_entries stream=sample_rate \
        -of default=noprint_wrappers=1:nokey=1 "$in_path" 2>/dev/null)
    sample_rate="${sample_rate:-44100}"
    echo -e "  ${DIM}  Detected sample rate: ${sample_rate} Hz${RESET}"
    echo ""

    # Pitch factor
    echo -ne "  ${CYAN}Pitch factor (e.g. 1.5 for higher, 0.75 for lower): ${RESET}"
    read -r pitch
    if [[ -z "$pitch" ]]; then echo -e "  ${RED}✗  No pitch value given.${RESET}"; pause; return; fi

    if ! echo "$pitch" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
        echo -e "  ${RED}✗  Invalid value. Enter a positive number like 1.5 or 0.75${RESET}"
        pause; return
    fi

    # Output filename
    echo -ne "  ${CYAN}Output filename (e.g. high_pitch.mp3): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    # Compute new sample rate = original * pitch factor (integer)
    local new_rate
    new_rate=$(awk "BEGIN{printf \"%d\", ${sample_rate} * ${pitch}}")

    echo ""
    echo -e "  ${YELLOW}⟳  Adjusting pitch by factor ${pitch}...${RESET}"
    echo -e "  ${DIM}  Resampling: ${sample_rate} Hz → ${new_rate} Hz → ${sample_rate} Hz${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    # asetrate shifts pitch by changing playback rate, aresample restores original rate
    ffmpeg -i "$in_path" \
        -filter:a "asetrate=${new_rate},aresample=${sample_rate}" \
        "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Pitch adjusted! Saved: ${out_path} (${size})${RESET}"
        echo -e "  ${DIM}  Factor ${pitch} applied — duration is unchanged.${RESET}"
    else
        echo -e "  ${RED}✗  Failed. Check the input file is a valid audio file.${RESET}"
    fi

    pause
}

# ============================================================
#  AUDIO MENU
# ============================================================
audio_menu() {
    while true; do
        show_banner
        echo -e "${MAGENTA}  ♪  AUDIO TOOLS${RESET}"
        echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
        echo ""
        echo -e "  ${WHITE}[1]${RESET} Merge Audio Files"
        echo -e "  ${WHITE}[2]${RESET} Trim / Cut Audio"
        echo -e "  ${WHITE}[3]${RESET} Change Speed"
        echo -e "  ${WHITE}[4]${RESET} Insert Silence"
        echo -e "  ${WHITE}[5]${RESET} Convert Format"
        echo -e "  ${WHITE}[6]${RESET} Extract Audio from Video"
        echo -e "  ${WHITE}[7]${RESET} Adjust Volume"
        echo -e "  ${WHITE}[8]${RESET} Fix Early Audio (Video Sync)"
        echo -e "  ${WHITE}[9]${RESET} Adjust Pitch"
        echo ""
        echo -e "  ${WHITE}[0]${RESET} ← Back to Main Menu"
        echo ""
        echo -ne "  ${CYAN}Choose option: ${RESET}"
        read -r choice

        case "$choice" in
            1) audio_merge ;;
            2) audio_trim ;;
            3) audio_speed ;;
            4) audio_silencer ;;
            5) audio_convert ;;
            6) audio_extract ;;
            7) audio_volume ;;
            8) audio_fix_early ;;
            9) audio_pitch ;;
            0) return ;;
            *) echo -e "  ${RED}  Invalid option.${RESET}"; sleep 1 ;;
        esac
    done
}

# ============================================================
#  VIDEO TOOLS
# ============================================================

# ── Video: Merge ─────────────────────────────────────────────
video_merge() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › MERGE FILES${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Merges multiple video files into one."
    echo ""
    echo -e "  ${WHITE}Are your videos the same quality/resolution?${RESET}"
    echo ""
    echo -e "  ${WHITE}[1]${RESET} Same quality  ${DIM}(fast, lossless copy)${RESET}"
    echo -e "  ${WHITE}[2]${RESET} Different quality  ${DIM}(re-encodes to unify)${RESET}"
    echo ""
    echo -ne "  ${CYAN}Choose: ${RESET}"
    read -r quality_choice

    if [[ "$quality_choice" != "1" && "$quality_choice" != "2" ]]; then
        echo -e "  ${RED}✗  Invalid choice.${RESET}"; pause; return
    fi

    echo ""
    echo -e "  Enter filenames separated by commas."
    echo -e "  ${DIM}Example: 1.mp4, 2.mp4, clip3.mp4${RESET}"
    echo ""
    echo -ne "  ${CYAN}Files to merge: ${RESET}"
    read -r user_input

    if [[ -z "$user_input" ]]; then
        echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return
    fi

    echo ""
    echo -e "  ${YELLOW}⟳  Locating files on device...${RESET}"
    echo ""

    parse_and_find_files "$user_input"
    if [[ $? -ne 0 ]]; then
        echo ""
        echo -e "  ${RED}✗  One or more files could not be found.${RESET}"
        pause; return
    fi

    if [[ ${#FILE_PATHS[@]} -lt 2 ]]; then
        echo -e "  ${RED}✗  Please provide at least 2 files to merge.${RESET}"
        pause; return
    fi

    echo -ne "  ${CYAN}Output filename (e.g. merged.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "${FILE_PATHS[0]}")
    local out_path="${out_dir}/${out_name}"

    # Build concat list file
    local list_file
    list_file=$(mktemp /tmp/ffmpeg_vconcat_XXXXXX.txt)
    for f in "${FILE_PATHS[@]}"; do
        echo "file '${f}'" >> "$list_file"
    done

    echo ""
    echo -e "  ${YELLOW}⟳  Merging ${#FILE_PATHS[@]} videos...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    if [[ "$quality_choice" == "1" ]]; then
        # Same quality — fast lossless copy
        ffmpeg -f concat -safe 0 -i "$list_file" -c copy "$out_path" -y 2>&1 | \
            grep -E "error|Error|size=|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done
    else
        # Different quality — re-encode to unify
        ffmpeg -f concat -safe 0 -i "$list_file" \
            -c:v libx264 -preset fast -crf 23 -c:a aac \
            "$out_path" -y 2>&1 | \
            grep -E "error|Error|size=|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done
    fi

    rm -f "$list_file"

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Merge complete! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Merge failed. Check that all files are valid video files.${RESET}"
        if [[ "$quality_choice" == "1" ]]; then
            echo -e "  ${DIM}  Tip: If videos have different resolutions/codecs, use option [2] instead.${RESET}"
        fi
    fi

    pause
}

# ── Video: Trim ───────────────────────────────────────────────
video_trim() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › TRIM / CUT${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Cuts a portion from a video file."
    echo -e "  ${DIM}You set a start time and how long the clip should be.${RESET}"
    echo ""

    # Input file
    echo -ne "  ${CYAN}Video filename (e.g. clip.mp4): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    # Show duration
    local duration
    duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$in_path" 2>/dev/null | \
        awk '{printf "%02d:%02d:%02d", int($1/3600), int(($1%3600)/60), int($1%60)}')
    if [[ -n "$duration" ]]; then
        echo -e "  ${DIM}  Total duration: ${duration}${RESET}"
    fi

    echo ""
    echo -e "  ${DIM}Time format: HH:MM:SS  (e.g. 00:01:10 = 1 minute 10 seconds)${RESET}"
    echo ""

    echo -ne "  ${CYAN}Start time (e.g. 00:00:10): ${RESET}"
    read -r start_time
    if [[ -z "$start_time" ]]; then echo -e "  ${RED}✗  No start time given.${RESET}"; pause; return; fi

    echo -ne "  ${CYAN}Duration to keep (e.g. 00:00:20): ${RESET}"
    read -r duration_keep
    if [[ -z "$duration_keep" ]]; then echo -e "  ${RED}✗  No duration given.${RESET}"; pause; return; fi

    echo -ne "  ${CYAN}Output filename (e.g. cut_video.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Trimming video...${RESET}"
    echo -e "  ${DIM}  Start: ${start_time}  |  Duration: ${duration_keep}${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    # -ss before -i = fast seek; -t = duration to keep
    ffmpeg -ss "$start_time" -i "$in_path" -t "$duration_keep" -c copy "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Trim complete! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Trim failed. Check your time values are within the video duration.${RESET}"
    fi

    pause
}

# ── Video: Remove Audio ───────────────────────────────────────
video_remove_audio() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › REMOVE AUDIO${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Strips the audio track from a video, producing a silent video."
    echo -e "  ${DIM}The video quality is untouched — only audio is removed.${RESET}"
    echo ""

    # Input file
    echo -ne "  ${CYAN}Video filename (e.g. input.mp4): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    # Show stream info
    echo ""
    echo -e "  ${DIM}Detected streams:${RESET}"
    ffprobe -v error -show_entries stream=codec_type,codec_name \
        -of default=noprint_wrappers=1 "$in_path" 2>/dev/null | \
        while IFS= read -r line; do echo -e "  ${DIM}  ${line}${RESET}"; done
    echo ""

    echo -ne "  ${CYAN}Output filename (e.g. muted.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Removing audio track...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    # -an = no audio, -c:v copy = keep video losslessly
    ffmpeg -i "$in_path" -an -c:v copy "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Audio removed! Saved: ${out_path} (${size})${RESET}"
        echo -e "  ${DIM}  Video stream is lossless — no quality loss.${RESET}"
    else
        echo -e "  ${RED}✗  Failed. Check the input is a valid video file.${RESET}"
    fi

    pause
}

# ── Video: Convert Format ─────────────────────────────────────
video_convert() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › CONVERT FORMAT${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Converts a video from one format to another."
    echo -e "  ${DIM}Supported: mp4, mkv, avi, mov, webm, flv, ts, etc.${RESET}"
    echo ""

    echo -ne "  ${CYAN}Video filename (e.g. clip.mkv): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    # Show current format info
    echo ""
    echo -e "  ${DIM}Current file info:${RESET}"
    ffprobe -v error -show_entries stream=codec_name,codec_type \
        -of default=noprint_wrappers=1 "$in_path" 2>/dev/null | \
        while IFS= read -r line; do echo -e "  ${DIM}  ${line}${RESET}"; done
    echo ""

    echo -e "  ${DIM}Include the new extension in the output name.${RESET}"
    echo -e "  ${DIM}Example: converted.mp4  or  output.mkv${RESET}"
    echo -ne "  ${CYAN}Output filename (e.g. converted.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    local out_ext="${out_name##*.}"
    out_ext="${out_ext,,}"

    # Pick codec args based on output format
    local vcodec acodec
    case "$out_ext" in
        mp4|m4v) vcodec="-c:v libx264 -preset fast -crf 23"; acodec="-c:a aac" ;;
        mkv)     vcodec="-c:v libx264 -preset fast -crf 23"; acodec="-c:a aac" ;;
        webm)    vcodec="-c:v libvpx-vp9 -crf 30 -b:v 0";   acodec="-c:a libopus" ;;
        avi)     vcodec="-c:v libx264 -preset fast -crf 23"; acodec="-c:a mp3" ;;
        mov)     vcodec="-c:v libx264 -preset fast -crf 23"; acodec="-c:a aac" ;;
        flv)     vcodec="-c:v libx264 -preset fast -crf 23"; acodec="-c:a aac" ;;
        ts)      vcodec="-c:v libx264 -preset fast -crf 23"; acodec="-c:a aac" ;;
        *)       vcodec="-c:v libx264 -preset fast -crf 23"; acodec="-c:a aac" ;;
    esac

    echo ""
    echo -e "  ${YELLOW}⟳  Converting to ${out_ext^^}...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    ffmpeg -i "$in_path" $vcodec $acodec "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Conversion complete! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Conversion failed. The input format may not be supported.${RESET}"
    fi

    pause
}

# ── Video: Compress ───────────────────────────────────────────
video_compress() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › COMPRESS VIDEO${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Reduces the file size of a video."
    echo ""

    echo -ne "  ${CYAN}Video filename (e.g. input.mp4): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    # Show current file size
    local cur_size
    cur_size=$(du -h "$in_path" | cut -f1)
    local cur_bytes
    cur_bytes=$(du -b "$in_path" | cut -f1)
    echo -e "  ${DIM}  Current size: ${cur_size}${RESET}"
    echo ""

    # Ask for target size
    echo -e "  ${DIM}Enter your target size. Examples: 50M, 100M, 500M, 1G${RESET}"
    echo -e "  ${DIM}Note: target size is approximate — FFmpeg uses 2-pass to get close.${RESET}"
    echo -e "  ${DIM}If you skip this, choose a compression mode instead.${RESET}"
    echo ""
    echo -ne "  ${CYAN}Target size (e.g. 50M) or press Enter to skip: ${RESET}"
    read -r target_size

    local use_target=false
    local target_bytes=0

    if [[ -n "$target_size" ]]; then
        # Convert target to bytes
        local unit="${target_size: -1}"
        local num="${target_size%?}"
        case "${unit^^}" in
            M) target_bytes=$(awk "BEGIN{printf \"%d\", $num * 1024 * 1024}") ;;
            G) target_bytes=$(awk "BEGIN{printf \"%d\", $num * 1024 * 1024 * 1024}") ;;
            K) target_bytes=$(awk "BEGIN{printf \"%d\", $num * 1024}") ;;
            *) echo -e "  ${RED}✗  Invalid unit. Use M, G, or K (e.g. 50M)${RESET}"; pause; return ;;
        esac

        if [[ "$target_bytes" -ge "$cur_bytes" ]]; then
            echo -e "  ${YELLOW}⚠  Target size is larger than the current file. Skipping target mode.${RESET}"
        else
            use_target=true
        fi
    fi

    # If no valid target, ask for compression mode
    if [[ "$use_target" == false ]]; then
        echo ""
        echo -e "  ${WHITE}Choose compression mode:${RESET}"
        echo ""
        echo -e "  ${WHITE}[1]${RESET} Fast compression   ${DIM}(H.264, ultrafast, good quality)${RESET}"
        echo -e "  ${WHITE}[2]${RESET} Heavy compression  ${DIM}(H.265, slower, smaller file)${RESET}"
        echo ""
        echo -ne "  ${CYAN}Choose: ${RESET}"
        read -r mode

        if [[ "$mode" != "1" && "$mode" != "2" ]]; then
            echo -e "  ${RED}✗  Invalid choice.${RESET}"; pause; return
        fi
    fi

    echo -ne "  ${CYAN}Output filename (e.g. compressed.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""

    if [[ "$use_target" == true ]]; then
        # 2-pass encoding to hit target size
        # bitrate (kbps) = (target_bytes * 8) / duration_seconds / 1000
        local duration_sec
        duration_sec=$(ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$in_path" 2>/dev/null | \
            awk '{printf "%d", $1}')

        if [[ -z "$duration_sec" || "$duration_sec" -eq 0 ]]; then
            echo -e "  ${RED}✗  Could not detect video duration.${RESET}"; pause; return
        fi

        local total_kbps
        total_kbps=$(awk "BEGIN{printf \"%d\", ($target_bytes * 8) / $duration_sec / 1000}")
        # Reserve ~128kbps for audio, rest for video
        local video_kbps=$(( total_kbps - 128 ))
        if [[ "$video_kbps" -lt 100 ]]; then video_kbps=100; fi

        echo -e "  ${YELLOW}⟳  2-pass compression targeting ~${target_size}...${RESET}"
        echo -e "  ${DIM}  Video bitrate: ${video_kbps}kbps | Audio: 128kbps${RESET}"
        echo -e "  ${DIM}  Pass 1 of 2...${RESET}"
        echo ""

        # Pass 1
        ffmpeg -y -i "$in_path" \
            -c:v libx264 -b:v "${video_kbps}k" \
            -pass 1 -an -f null /dev/null 2>&1 | \
            grep -E "error|Error|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

        echo -e "  ${DIM}  Pass 2 of 2...${RESET}"
        echo ""

        # Pass 2
        ffmpeg -y -i "$in_path" \
            -c:v libx264 -b:v "${video_kbps}k" \
            -pass 2 -c:a aac -b:a 128k \
            "$out_path" 2>&1 | \
            grep -E "error|Error|size=|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

        # Clean up 2-pass log files
        rm -f ffmpeg2pass-0.log ffmpeg2pass-0.log.mbtree

    elif [[ "$mode" == "1" ]]; then
        echo -e "  ${YELLOW}⟳  Fast compressing with H.264...${RESET}"
        echo -e "  ${DIM}  Output → ${out_path}${RESET}"
        echo ""
        ffmpeg -i "$in_path" -vcodec libx264 -preset ultrafast -crf 25 \
            "$out_path" -y 2>&1 | \
            grep -E "error|Error|size=|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done
    else
        echo -e "  ${YELLOW}⟳  Heavy compressing with H.265...${RESET}"
        echo -e "  ${DIM}  Output → ${out_path}${RESET}"
        echo ""
        ffmpeg -i "$in_path" -vcodec libx265 -crf 23 -preset superfast \
            -acodec copy "$out_path" -y 2>&1 | \
            grep -E "error|Error|size=|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done
    fi

    if [[ -f "$out_path" ]]; then
        local new_size new_bytes savings
        new_size=$(du -h "$out_path" | cut -f1)
        new_bytes=$(du -b "$out_path" | cut -f1)
        savings=$(awk "BEGIN{printf \"%.1f\", (1 - $new_bytes/$cur_bytes) * 100}")
        echo ""
        echo -e "  ${GREEN}✓  Compression complete!${RESET}"
        echo -e "  ${WHITE}┌─ Size Comparison ────────────────────────────┐${RESET}"
        echo -e "  ${WHITE}│${RESET}  Before : ${YELLOW}${cur_size}${RESET}"
        echo -e "  ${WHITE}│${RESET}  After  : ${GREEN}${new_size}${RESET}"
        echo -e "  ${WHITE}│${RESET}  Saved  : ${GREEN}${savings}% reduction${RESET}"
        echo -e "  ${WHITE}└──────────────────────────────────────────────┘${RESET}"
    else
        echo -e "  ${RED}✗  Compression failed. Check the input file.${RESET}"
    fi

    pause
}

# ── Video: Add Audio to Video ─────────────────────────────────
video_add_audio() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › ADD AUDIO TO VIDEO${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Replaces or adds an audio track to a video file."
    echo -e "  ${DIM}The video's original audio (if any) will be replaced.${RESET}"
    echo ""

    # Input video
    echo -ne "  ${CYAN}Video filename (e.g. video.mp4): ${RESET}"
    read -r vid_name
    if [[ -z "$vid_name" ]]; then echo -e "  ${RED}✗  No video provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for video...${RESET}"
    local vid_path
    vid_path=$(find_file "$vid_name")
    if [[ -z "$vid_path" ]]; then
        echo -e "  ${RED}✗  File not found: $vid_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $vid_path${RESET}"

    local vid_dur_sec
    vid_dur_sec=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$vid_path" 2>/dev/null | \
        awk '{printf "%d", $1}')
    local vid_dur
    vid_dur=$(awk "BEGIN{printf \"%02d:%02d:%02d\", int($vid_dur_sec/3600), int(($vid_dur_sec%3600)/60), int($vid_dur_sec%60)}")
    echo -e "  ${DIM}  Video duration: ${vid_dur}${RESET}"
    echo ""

    # Input audio
    echo -ne "  ${CYAN}Audio filename (e.g. music.mp3): ${RESET}"
    read -r aud_name
    if [[ -z "$aud_name" ]]; then echo -e "  ${RED}✗  No audio provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for audio...${RESET}"
    local aud_path
    aud_path=$(find_file "$aud_name")
    if [[ -z "$aud_path" ]]; then
        echo -e "  ${RED}✗  File not found: $aud_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $aud_path${RESET}"

    local aud_dur
    aud_dur=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$aud_path" 2>/dev/null | \
        awk '{printf "%02d:%02d:%02d", int($1/3600), int(($1%3600)/60), int($1%60)}')
    echo -e "  ${DIM}  Audio duration: ${aud_dur}${RESET}"

    echo ""
    echo -e "  ${WHITE}What should happen if audio is shorter than the video?${RESET}"
    echo ""
    echo -e "  ${WHITE}[1]${RESET} Stop video at end of audio"
    echo -e "  ${WHITE}[2]${RESET} Keep full video (audio stops, video continues silently)"
    echo -e "  ${WHITE}[3]${RESET} Loop audio until video ends"
    echo ""
    echo -ne "  ${CYAN}Choose: ${RESET}"
    read -r length_choice

    echo ""
    echo -ne "  ${CYAN}Output filename (e.g. final.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$vid_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Adding audio to video...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    if [[ "$length_choice" == "1" ]]; then
        ffmpeg -i "$vid_path" -i "$aud_path" \
            -map 0:v -map 1:a \
            -c:v copy -c:a aac \
            -shortest \
            "$out_path" -y 2>&1 | \
            grep -E "error|Error|size=|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    elif [[ "$length_choice" == "3" ]]; then
        # Loop audio to cover full video duration using -stream_loop -1 then trim to video length
        ffmpeg -i "$vid_path" -stream_loop -1 -i "$aud_path" \
            -map 0:v -map 1:a \
            -c:v copy -c:a aac \
            -shortest \
            "$out_path" -y 2>&1 | \
            grep -E "error|Error|size=|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    else
        ffmpeg -i "$vid_path" -i "$aud_path" \
            -map 0:v -map 1:a \
            -c:v copy -c:a aac \
            "$out_path" -y 2>&1 | \
            grep -E "error|Error|size=|time=" | \
            while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done
    fi

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Done! Audio added. Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Failed. Make sure both files are valid and compatible.${RESET}"
    fi

    pause
}

# ── Video: Adjust Volume ──────────────────────────────────────
video_volume() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › ADJUST VOLUME${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Changes the audio volume of a video file."
    echo -e "  ${DIM}Video quality is untouched — only audio level changes.${RESET}"
    echo ""
    echo -e "  ${DIM}Volume examples:${RESET}"
    echo -e "  ${DIM}   2.0   → doubles the volume${RESET}"
    echo -e "  ${DIM}   0.5   → halves the volume${RESET}"
    echo -e "  ${DIM}   1.0   → no change${RESET}"
    echo -e "  ${DIM}   10dB  → raise by 10 decibels${RESET}"
    echo -e "  ${DIM}  -5dB   → lower by 5 decibels${RESET}"
    echo ""

    echo -ne "  ${CYAN}Video filename (e.g. input.mp4): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    # Detect and show current volume
    echo ""
    echo -e "  ${YELLOW}⟳  Analysing current volume...${RESET}"
    local vol_info mean_vol max_vol
    vol_info=$(ffmpeg -i "$in_path" -af volumedetect -f null /dev/null 2>&1 | \
               grep -E "mean_volume|max_volume")
    mean_vol=$(echo "$vol_info" | grep "mean_volume" | awk '{print $5, $6}')
    max_vol=$(echo  "$vol_info" | grep "max_volume"  | awk '{print $5, $6}')

    if [[ -n "$mean_vol" ]]; then
        echo -e "  ${WHITE}┌─ Current Volume Levels ──────────────────────┐${RESET}"
        echo -e "  ${WHITE}│${RESET}  Mean volume : ${CYAN}${mean_vol}${RESET}"
        echo -e "  ${WHITE}│${RESET}  Max  volume : ${CYAN}${max_vol}${RESET}"
        echo -e "  ${WHITE}└──────────────────────────────────────────────┘${RESET}"
    fi

    echo ""
    echo -ne "  ${CYAN}New volume (e.g. 2.0 or 10dB or -5dB): ${RESET}"
    read -r vol_val
    if [[ -z "$vol_val" ]]; then echo -e "  ${RED}✗  No value given.${RESET}"; pause; return; fi

    # Validate: number with optional dB suffix, or plain number
    if ! echo "$vol_val" | grep -qiE '^[+-]?[0-9]+(\.[0-9]+)?(dB)?$'; then
        echo -e "  ${RED}✗  Invalid. Use a number like 2.0, 0.5, 10dB or -5dB${RESET}"
        pause; return
    fi

    echo -ne "  ${CYAN}Output filename (e.g. louder.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Adjusting volume to ${vol_val}...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    ffmpeg -i "$in_path" -filter:a "volume=${vol_val}" -c:v copy "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Done! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Failed. Ensure the video has an audio track.${RESET}"
    fi

    pause
}

# ── Video: Fix Early Video (Video ahead of audio) ─────────────
video_fix_early() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › FIX EARLY VIDEO (SYNC)${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Use this when the video is ahead of the audio."
    echo -e "  It delays the video track so it lines up with the sound."
    echo ""
    echo -e "  ${DIM}Decimals allowed: 0.5, 1.0, 2.5, etc.${RESET}"
    echo ""

    echo -ne "  ${CYAN}Video filename (e.g. input.mp4): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    local duration
    duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$in_path" 2>/dev/null | \
        awk '{printf "%02d:%02d:%02d", int($1/3600), int(($1%3600)/60), int($1%60)}')
    [[ -n "$duration" ]] && echo -e "  ${DIM}  Duration: ${duration}${RESET}"

    echo ""
    echo -e "  ${DIM}How many seconds is the video ahead of the audio?${RESET}"
    echo -ne "  ${CYAN}Delay amount in seconds (e.g. 1.5): ${RESET}"
    read -r delay_sec
    if [[ -z "$delay_sec" ]]; then echo -e "  ${RED}✗  No delay value given.${RESET}"; pause; return; fi

    if ! echo "$delay_sec" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
        echo -e "  ${RED}✗  Invalid. Enter a positive number like 1.5 or 3${RESET}"
        pause; return
    fi

    echo -ne "  ${CYAN}Output filename (e.g. fixed.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    echo ""
    echo -e "  ${YELLOW}⟳  Delaying video by ${delay_sec}s to fix sync...${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    # -itsoffset on second input delays it; map 1:v = delayed video, map 0:a = original audio
    ffmpeg -i "$in_path" \
           -itsoffset "$delay_sec" -i "$in_path" \
           -map 1:v -map 0:a \
           -c:v copy -c:a aac \
           "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Sync fixed! Saved: ${out_path} (${size})${RESET}"
        echo -e "  ${DIM}  Video delayed by ${delay_sec}s — audio is now in sync.${RESET}"
    else
        echo -e "  ${RED}✗  Failed. Make sure the file has both video and audio tracks.${RESET}"
    fi

    pause
}

# ── Video: Change Speed ───────────────────────────────────────
video_speed() {
    show_banner
    echo -e "${BLUE}  ▶  VIDEO › CHANGE SPEED${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Changes the playback speed of a video (and its audio)."
    echo ""
    echo -e "  ${DIM}Speed examples:${RESET}"
    echo -e "  ${DIM}   0.5 → half speed (slow motion)${RESET}"
    echo -e "  ${DIM}   1.0 → original speed${RESET}"
    echo -e "  ${DIM}   1.5 → 1.5x faster${RESET}"
    echo -e "  ${DIM}   2.0 → double speed${RESET}"
    echo -e "  ${DIM}  Note: audio pitch stays natural (atempo filter used)${RESET}"
    echo ""

    echo -ne "  ${CYAN}Video filename (e.g. clip.mp4): ${RESET}"
    read -r in_name
    if [[ -z "$in_name" ]]; then echo -e "  ${RED}✗  No input provided.${RESET}"; pause; return; fi

    echo ""
    echo -e "  ${YELLOW}⟳  Searching for file...${RESET}"
    local in_path
    in_path=$(find_file "$in_name")
    if [[ -z "$in_path" ]]; then
        echo -e "  ${RED}✗  File not found: $in_name${RESET}"
        pause; return
    fi
    echo -e "  ${GREEN}✓  Found: $in_path${RESET}"

    local duration
    duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$in_path" 2>/dev/null | \
        awk '{printf "%02d:%02d:%02d", int($1/3600), int(($1%3600)/60), int($1%60)}')
    [[ -n "$duration" ]] && echo -e "  ${DIM}  Current duration: ${duration}${RESET}"

    echo ""
    echo -ne "  ${CYAN}Speed multiplier (e.g. 2.0): ${RESET}"
    read -r speed
    if [[ -z "$speed" ]]; then echo -e "  ${RED}✗  No speed value given.${RESET}"; pause; return; fi

    if ! echo "$speed" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
        echo -e "  ${RED}✗  Invalid value. Use a number like 0.5 or 2.0${RESET}"
        pause; return
    fi

    echo -ne "  ${CYAN}Output filename (e.g. fast.mp4): ${RESET}"
    read -r out_name
    if [[ -z "$out_name" ]]; then echo -e "  ${RED}✗  No output name given.${RESET}"; pause; return; fi

    local out_dir
    out_dir=$(dirname "$in_path")
    local out_path="${out_dir}/${out_name}"

    # Video PTS factor = 1/speed (setpts)
    local pts_factor
    pts_factor=$(awk "BEGIN{printf \"%.6f\", 1.0 / $speed}")

    # Build chained atempo for audio (same logic as audio_speed)
    local atempo_filter=""
    local remaining
    remaining=$(echo "$speed" | awk '{printf "%.6f", $1}')

    while true; do
        local val
        if awk "BEGIN{exit !($remaining > 2.0)}"; then
            val="2.0"
            remaining=$(awk "BEGIN{printf \"%.6f\", $remaining / 2.0}")
        elif awk "BEGIN{exit !($remaining < 0.5)}"; then
            val="0.5"
            remaining=$(awk "BEGIN{printf \"%.6f\", $remaining / 0.5}")
        else
            val="$remaining"
            remaining="1.0"
        fi

        if [[ -z "$atempo_filter" ]]; then
            atempo_filter="atempo=${val}"
        else
            atempo_filter="${atempo_filter},atempo=${val}"
        fi

        if awk "BEGIN{exit !(${remaining} >= 0.9999 && ${remaining} <= 1.0001)}"; then
            break
        fi
    done

    echo ""
    echo -e "  ${YELLOW}⟳  Changing speed to ${speed}x...${RESET}"
    echo -e "  ${DIM}  Video filter: setpts=${pts_factor}*PTS${RESET}"
    echo -e "  ${DIM}  Audio filter: ${atempo_filter}${RESET}"
    echo -e "  ${DIM}  Output → ${out_path}${RESET}"
    echo ""

    ffmpeg -i "$in_path" \
        -filter:v "setpts=${pts_factor}*PTS" \
        -filter:a "$atempo_filter" \
        "$out_path" -y 2>&1 | \
        grep -E "error|Error|size=|time=" | \
        while IFS= read -r line; do echo -e "  ${DIM}${line}${RESET}"; done

    if [[ -f "$out_path" ]]; then
        local size
        size=$(du -h "$out_path" | cut -f1)
        echo -e "  ${GREEN}✓  Speed changed! Saved: ${out_path} (${size})${RESET}"
    else
        echo -e "  ${RED}✗  Failed. Check the input file is a valid video.${RESET}"
    fi

    pause
}

# ============================================================
#  VIDEO MENU
# ============================================================
video_menu() {
    while true; do
        show_banner
        echo -e "${BLUE}  ▶  VIDEO TOOLS${RESET}"
        echo -e "${DIM}  ─────────────────────────────────────────────────${RESET}"
        echo ""
        echo -e "  ${WHITE}[1]${RESET} Merge Videos"
        echo -e "  ${WHITE}[2]${RESET} Trim / Cut Video"
        echo -e "  ${WHITE}[3]${RESET} Remove Audio"
        echo -e "  ${WHITE}[4]${RESET} Convert Format"
        echo -e "  ${WHITE}[5]${RESET} Compress Video"
        echo -e "  ${WHITE}[6]${RESET} Add Audio to Video"
        echo -e "  ${WHITE}[7]${RESET} Adjust Volume"
        echo -e "  ${WHITE}[8]${RESET} Fix Early Video (Sync)"
        echo -e "  ${WHITE}[9]${RESET} Change Speed"
        echo ""
        echo -e "  ${WHITE}[0]${RESET} ← Back to Main Menu"
        echo ""
        echo -ne "  ${CYAN}Choose option: ${RESET}"
        read -r choice

        case "$choice" in
            1) video_merge ;;
            2) video_trim ;;
            3) video_remove_audio ;;
            4) video_convert ;;
            5) video_compress ;;
            6) video_add_audio ;;
            7) video_volume ;;
            8) video_fix_early ;;
            9) video_speed ;;
            0) return ;;
            *) echo -e "  ${RED}  Invalid option.${RESET}"; sleep 1 ;;
        esac
    done
}

# ============================================================
#  MAIN MENU
# ============================================================
main_menu() {
    check_ffmpeg

    while true; do
        show_banner
        echo -e "  ${WHITE}What would you like to work with?${RESET}"
        echo ""
        echo -e "  ${MAGENTA}[1]${RESET}  ♪  Audio Tools"
        echo -e "  ${BLUE}[2]${RESET}  ▶  Video Tools"
        echo ""
        echo -e "  ${WHITE}[0]${RESET}  ✕  Exit"
        echo ""
        echo -ne "  ${CYAN}Choose option: ${RESET}"
        read -r choice

        case "$choice" in
            1) audio_menu ;;
            2) video_menu ;;
            0)
                show_banner
                echo -e "  ${GREEN}Goodbye! Happy editing. 🎵${RESET}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "  ${RED}  Invalid option. Try 1, 2, or 0.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ── Entry Point ───────────────────────────────────────────────
main_menu
```

---

## 💾 Step 3 — Save the File in Nano

After pasting the script, save and exit using these **3 key presses in order**:

```
Ctrl + O       →  Press this to Write/Save the file
Enter          →  Press this to confirm the filename
Ctrl + X       →  Press this to Exit nano
```

---

## ▶️ Step 4 — Make It Executable and Run

```bash
chmod +x ffmpeg_tools.sh
bash ffmpeg_tools.sh
```

---

## ⚡ Step 5 — Add Alias (Optional)

If you want to launch the tool by just typing `av` anywhere in Termux:

```bash
echo "alias av='bash ~/ffmpeg_tools.sh'" >> ~/.bashrc && source ~/.bashrc
```

After that, simply type:

```bash
av
```

> This step is optional. You can always run it with `bash ffmpeg_tools.sh` without the alias.

---

## 🛠️ Features

### ♪ Audio Tools — 9 options

| # | Tool | Description |
|---|------|-------------|
| 1 | Merge Audio Files | Combine multiple audio files into one |
| 2 | Trim / Cut Audio | Extract a portion by start time + duration |
| 3 | Change Speed | Speed up or slow down audio (0.5x to 100x) |
| 4 | Insert Silence | Inject a gap of silence at any timestamp |
| 5 | Convert Format | Convert between mp3, opus, aac, flac, wav, ogg, m4a |
| 6 | Extract Audio from Video | Rip the audio track out of any video file |
| 7 | Adjust Volume | Change volume in dB — shows before/after levels |
| 8 | Fix Early Audio (Video Sync) | Delay audio in a video to fix sync issues |
| 9 | Adjust Pitch | Raise or lower pitch without changing duration |

### ▶️ Video Tools — 9 options

| # | Tool | Description |
|---|------|-------------|
| 1 | Merge Videos | Merge same quality (fast copy) or different quality (re-encode) |
| 2 | Trim / Cut Video | Cut a clip by start time + duration |
| 3 | Remove Audio | Strip audio track, keep video losslessly |
| 4 | Convert Format | Convert between mp4, mkv, avi, mov, webm, flv, ts |
| 5 | Compress Video | Target file size (2-pass) or fast/heavy mode with size report |
| 6 | Add Audio to Video | Add/replace audio — stop at end, keep full, or loop audio |
| 7 | Adjust Volume | Change video audio by multiplier (2.0) or decibels (10dB) |
| 8 | Fix Early Video (Sync) | Delay video track to fix sync when video is ahead of audio |
| 9 | Change Speed | Change speed of video and audio together |

---

## 📋 How It Works

- **No folder navigation needed** — type any filename and the script searches your entire device automatically
- **Output files** are saved in the same folder as the input file
- **FFmpeg is auto-installed** if missing when you first run the script
- Run `termux-setup-storage` once if files cannot be found (grants storage permission)

---

## 📄 License

MIT — free to use, modify, and share.
