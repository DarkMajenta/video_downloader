#!/bin/bash

# Установка веб-сервера (Apache)
sudo apt update
sudo apt install apache2

# Установка PHP
sudo apt install php libapache2-mod-php

# Установка MySQL
sudo apt install mysql-server

# Создание базы данных
mysql -u root -p <<EOF
CREATE DATABASE video_uploader;
USE video_uploader;
CREATE TABLE videos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    video_name VARCHAR(255),
    status VARCHAR(100)
);
EOF

# Установка FFmpeg для обработки видео
sudo apt install ffmpeg

# Создание папки для сохранения видео и изображений
mkdir /videos
mkdir /images

# Создать папку для временного сохранения видео для каждого пользователя
mkdir /video

# Добавить задание cron для удаления обработанных видео
(crontab -l ; echo "0 0 * * * find /video/*/* -mtime +1 -exec rm -f {} \;") | crontab -

# Веб-страница для загрузки видео (video_upload.php)
cat > /var/www/html/video_upload.php <<EOF
<?php
if (\$_FILES['video']['size'] > 10 * 1024 * 1024 * 1024) {
    echo "Размер файла превышает 10 Гб!";
    exit;
}

\$userId = \$_POST['user_id'];
\$targetDir = "/video/user_\$userId/";
\$targetFile = \$targetDir . basename(\$_FILES["video"]["name"]);
\$uploadOk = 1;
\$videoFileType = strtolower(pathinfo(\$targetFile, PATHINFO_EXTENSION));

// Проверка формата файла (только mp4)
if (\$videoFileType != "mp4") {
    echo "Можно загружать только видео в формате mp4!";
    \$uploadOk = 0;
}

// Проверка наличия ошибок при загрузке
if (\$uploadOk == 0) {
    echo "Возникла ошибка при загрузке файла!";
} else {
    if (move_uploaded_file(\$_FILES["video"]["tmp_name"], \$targetFile)) {
        echo "Видео успешно загружено и сохранено.";
        // Сохранение информации о загруженном видео в базу данных
        \$conn = new mysqli("localhost", "root", "", "video_uploader");
        \$videoName = \$conn->real_escape_string(\$_FILES["video"]["name"]);
        \$conn->query("INSERT INTO videos (user_id, video_name, status) VALUES (\$userId, '\$videoName', 'Загружено')");
        \$conn->close();
    } else {
        echo "Возникла ошибка при сохранении видео!";
    }
}
?>
EOF

# Веб-страница для просмотра списка загруженных видео (video_list.php)
cat > /var/www/html/video_list.php <<EOF
<?php
\$conn = new mysqli("localhost", "root", "", "video_uploader");
\$result = \$conn->query("SELECT * FROM videos");
if (\$result->num_rows > 0) {
    while (\$row = \$result->fetch_assoc()) {
        echo "ID: " . \$row["id"] . ", UserID: " . \$row["user_id"] . ", Название: " . \$row["video_name"] . ", Статус: " . \$row["status"] . "<br>";
    }
} else {
    echo "Нет загруженных видео.";
}
\$conn->close();
?>
EOF

# Скрипт обработки видео (video_processing.sh)
cat > video_processing.sh <<EOF
#!/bin/bash

# Измените путь до папки с загруженными видео и изображениями
video_dir="/video/"
image_dir="/images/"

# Получение списка загруженных, но еще не обработанных видео
conn=\$(mysql -u root -p -e "SELECT * FROM video_uploader.videos WHERE status = 'Загружено'")
video_list=()
while read -r line; do
    video_list+=(\$line)
done <<< "\$conn"

# Обработка каждого видео
for video_info in "\${video_list[@]}"
do
    IFS=$'\t' read -ra video <<< "\$video_info"
    video_id=\${video[0]}
    video_user_id=\${video[1]}
    video_name=\${video[2]}
    video_path="\$video_dir/user_\$video_user_id/\$video_name"
    image_name="\${video_name%.*}"

    # Извлечение каждого пятого кадра из видео
    ffmpeg -i "\$video_path" -vf "select='not(mod(n,5))',setpts=N/30/TB" -r 1 "\$image_dir\$image_name-%04d.png"
    ffmpeg -i "\$video_path" -vf "select='not(mod(n,5))',setpts=N/30/TB" -r 1 "\$image_dir\$image_name-%04d.webp"

    # Обновление статуса в базе данных
    mysql -u root -p -e "UPDATE video_uploader.videos SET status = 'Обработано' WHERE id = \$video_id"
done
EOF

# Добавление прав на выполнение скрипта обработки видео
chmod +x video_processing.sh
