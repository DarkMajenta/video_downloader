#!/bin/bash

# Путь до папки с видео
video_dir="/path/to/videos/"

# Путь до папки с изображениями
image_dir="/images/user_id1/"

# Запрос пользователя для задания частоты кадров
read -p "Введите частоту кадров (количество кадров в секунду): " framerate

# Имя видеофайла
video_file="video.mp4"

# Конвертация видео в изображения
ffmpeg -i "${video_dir}${video_file}" -vf "select='not(mod(n,${framerate}))',setpts=N/30/TB" -r 1 "${image_dir}image-%04d.png"
ffmpeg -i "${video_dir}${video_file}" -vf "select='not(mod(n,${framerate}))',setpts=N/30/TB" -r 1 "${image_dir}image-%04d.webp"
