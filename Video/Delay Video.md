When Video is early

pkg install ffmpeg

ffmpeg -i "input.mp4" -itsoffset 10.0 -i "input.mp4" -map 1:v -map 0:a -c:v copy -c:a aac "output_fixed.mp4"

In place of 10.0 put the delayed time period and replace input.mp4by filename