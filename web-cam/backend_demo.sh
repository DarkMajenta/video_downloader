#!/bin/bash

# Установка переменных
video_path="/путь/к/загруженному/видео.webm"
output_images_folder="/images/user_id1/"
database_host="localhost"
database_name="имя_базы_данных"
database_user="пользователь_базы_данных"
database_password="пароль_базы_данных"

# Определение временной папки для обработки
temp_folder=$(mktemp -d)

# Преобразование видео в изображения с использованием FFmpeg
ffmpeg -i "$video_path" -r 1 -vf "select='not(mod(n,100))',scale=320:-1" "$temp_folder/image-%d.jpg"

# Создание папки для сохранения изображений
mkdir -p "$output_images_folder"

# Конвертация изображений в формат PNG и сохранение в папке
for filepath in "$temp_folder"/*.jpg; do
    filename=$(basename "$filepath")
    png_filepath="$output_images_folder/${filename%.*}.png"
    webp_filepath="$output_images_folder/${filename%.*}.webp"

    # Конвертация в PNG
    ffmpeg -i "$filepath" "$png_filepath"

    # Конвертация в WebP
    ffmpeg -i "$filepath" -q:v 80 "$webp_filepath"
done

# Подключение к базе данных MySQL
mysql -h "$database_host" -u "$database_user" -p"$database_password" "$database_name" << EOF
    -- Создание таблицы для хранения изображений, если она не существует
    CREATE TABLE IF NOT EXISTS images (
        id INT(11) AUTO_INCREMENT PRIMARY KEY,
        filename VARCHAR(255) NOT NULL
    );

    -- Очистка таблицы изображений перед загрузкой новых данных
    TRUNCATE TABLE images;

    -- Загрузка изображений в базу данных
    LOAD DATA LOCAL INFILE '$temp_folder/image-%d.jpg'
    INTO TABLE images
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
    LINES TERMINATED BY '\n'
    (filename);

EOF

# Удаление временной папки
rm -rf "$temp_folder"
