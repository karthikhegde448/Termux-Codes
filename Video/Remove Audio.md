pkg install ffmpeg

ffmpeg -i "input_video.mp4" -an -c:v copy "output_muted.mp4"
