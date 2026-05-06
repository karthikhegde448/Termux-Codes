pkg install ffmpeg

ffmpeg -i "input.mp3" -filter:a "asetrate=44100*1.5,aresample=44100" "high_pitch.mp3"
