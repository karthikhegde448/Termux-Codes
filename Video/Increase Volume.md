pkg install ffmpeg

ffmpeg -i "input_video.mp4" -filter:a "volume=2.0" -c:v copy "louder_video.mp4"

Change 2.0 for different volumes 
2.0 doubles the volume
Can even write volume in decibels 
as 10dB
