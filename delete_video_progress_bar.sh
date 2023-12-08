#!/bin/bash

# Путь до папки с видео
video_dir="/path/to/videos/"

# Путь до папки с изображениями
image_dir="/images/user_id1/"

# Имя видеофайла
video_file="video.mp4"

# Удаляем видеофайл, чтобы прервать обработку
trap '[[ -f "${video_dir}${video_file}" ]] && rm "${video_dir}${video_file}"; exit' INT TERM EXIT

# Функция для отображения полосы готовности
function show_progress() {
  local duration=$1

  while true; do
    # Получение текущей позиции видео обработки
    local position=$(ls -1 "${image_dir}"/image-*.png 2>/dev/null | wc -l)
    # Вычисление процента выполнения
    local progress=$(awk "BEGIN {printf \"%.2f\", ${position} / ${duration} * 100}")
    # Вычисление оставшегося времени
    local remaining=$(awk "BEGIN {printf \"%02d:%02d:%02d\", int((${duration} - ${position}) / 3600), int((${duration} - ${position}) % 3600 / 60), int((${duration} - ${position}) % 60)}")

    # Очистка строки вывода
    printf "\r\033[K"
    # Вывод полосы готовности
    printf "Progress: [%-50s] %.2f%%  Remaining Time: %s" $(printf "=%.0s" $(seq 1 $(awk "BEGIN {print int(${progress} / 2)}"))) ${progress} ${remaining}

    # Прерывание цикла при завершении обработки видео
    if [[ ${position} -eq ${duration} ]]; then
      break
    fi

    sleep 1
  done

  # Завершение строки вывода
  printf "\nAll frames processed\n"
}

# Получение общей длительности видео в кадрах
duration=$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 "${video_dir}${video_file}")

# Получение пятого кадра из видео и сохранение в форматах PNG и WebP
ffmpeg -i "${video_dir}${video_file}" -vf "select='not(mod(n,5))',setpts=N/30/TB" -r 1 "${image_dir}image-%04d.png" &
ffmpeg_pid=$!

# Ожидание обработки видео с отображением полосы готовности
show_progress ${duration}

# Ожидание завершения всех процессов
wait ${ffmpeg_pid}
