pkg install ffmpeg

ffmpeg -i "input.mp3" -filter:a "volume=2.0" "louder_audio.mp3"
 

Change 2.0 to different volumes 
2.0 doubles the initial volume