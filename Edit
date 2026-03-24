Add watermark of a photo in video

ffmpeg -i "input_video.mp4" -i "watermark.png" -filter_complex \
"[1][0]scale2ref=w=oh*mdar:h=ih*0.15[logo][video];[video][logo]overlay=W-w-10:10" \
-c:v libx264 -preset faster -pix_fmt yuv420p -c:a copy -crf 28 "output_watermarked.mp4"
 

replace watermark.png by watermark image and also replace input video by the original name of the video

CRF value 
CRF Value 
18 – 20 High (Lossless) 
Huge Archiving important projects or 4K videos.
23 Standard (Default) Medium-Large High-quality YouTube uploads or PC viewing.
26 – 28 
Balanced Small Recommended for mobile (WhatsApp, Gallery).
30 – 35 
Medium-Low Very Small Quick sharing of lecture clips or long study videos.
40+ 
Low Tiny Only use if you have almost no storage space left.

