Fast compressing

pkg install ffmpeg 

ffmpeg -i input.mp4 -vcodec libx264 -preset ultrafast -crf 25 output.mp4
 

Just go to the selected folder using cd 

Slower but heavy compression 

ffmpeg -i input.mp4 -vcodec libx265 -crf 23 -preset superfast -acodec copy output.mp4



