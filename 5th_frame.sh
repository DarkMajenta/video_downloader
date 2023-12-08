#!/bin/bash

# Путь до папки с видео
video_dir="/path/to/videos/"

# Путь до папки с изображениями
image_dir="/images/user_id1/"

# Получение пятого кадра из видео и сохранение в форматах PNG и WebP
ffmpeg -i "${video_dir}video.mp4" -vf "select='not(mod(n,5))',setpts=N/30/TB" -r 1 "${image_dir}image-%04d.png"
ffmpeg -i "${video_dir}video.mp4" -vf "select='not(mod(n,5))',setpts=N/30/TB" -r 1 "${image_dir}image-%04d.webp"
