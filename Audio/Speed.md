pkg install ffmpeg

ffmpeg -i "input.mp3" -filter:a "atempo=2.0" -vn "fast_audio.mp3"

Change 2.0 for different speed
