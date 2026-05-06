pkg install ffmpeg


ffmpeg -f concat -safe 0 -i <(for f in *.mp3; do echo "file '$PWD/$f'"; done) -c copy "merged_output.mp3"


Just enter the folder using cd and rewrite the name of the output as you want