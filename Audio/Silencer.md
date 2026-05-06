ffmpeg -i "input.mp3" -filter_complex \
"anullsrc=r=44100:cl=stereo:d=5[silence]; \
[0:a]atrim=end=10[part1]; \
[0:a]atrim=start=10[part2]; \
[part1][silence][part2]concat=n=3:v=0:a=1" \
"output.mp3"

The Gap Duration (d=5): Inside the anullsrc section, change 5 to the number of seconds of silence you want to insert.

The Split Point (end=10 and start=10): This is the "timestamp" where the silence will be injected. Change 10 to the second mark where you want the gap to appear.

Note: Both numbers must be the same so the audio isn't cut or repeated.