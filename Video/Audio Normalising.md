pkg install ffmpeg

ffmpeg -i "input.mp4" -af loudnorm -c:v copy "normalized_video.mp4"