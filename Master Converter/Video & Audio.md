pkg update && pkg upgrade
pkg install ffmpeg

ffmpeg -i "input" -c copy "output"

Special: (mkv to MP3)
ffmpeg -i "input_video.mkv" -vn -c:a copy "output.m4a"

ffmpeg -i "output.m4a" -q:a 2 "trial.mp3"