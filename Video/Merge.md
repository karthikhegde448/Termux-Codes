For videos of same quality 

ffmpeg -f concat -safe 0 -i <(for f in *.mp4; do echo "file '$PWD/$f'"; done) -c copy "fast_merge.mp4"

Keep the video in specific folder and write cd 

For videos of different quality

ffmpeg -f concat -safe 0 -i <(for f in *.mp4; do echo "file '$PWD/$f'"; done) -c:v libx264 -preset fast -crf 23 -c:a aac "unified_merged_video.mp4"
 
Keep the video in specific folder and write cd 
