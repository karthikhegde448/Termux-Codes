pkg install ffmpeg

ffmpeg -ss 00:00:10 -i "input.mp4" -t 00:00:20 -c copy "cut_video.mp4"


00:00:30 initial time
00:00:10 time period of trim


Replace input.mp3
