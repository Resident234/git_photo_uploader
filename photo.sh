#!/bin/bash

# пример вызова скрипта:  
#bash photo.sh "/d/PHOTO"

# В начале скрипта
export LANG=en_US.UTF-8

# Указываем путь к папке (первый аргумент)
TARGET_DIR="$1"

# todo сохранять текущий прогресс

# Проверяем, передан ли аргумент
if [ -z "$TARGET_DIR" ]; then
  echo "Ошибка: Укажите путь к папке!"
  sleep 30
  exit 1
fi

# Проверяем, существует ли указанная папка
if [ ! -d "$TARGET_DIR" ]; then
  echo "Ошибка: Указанная папка не существует!"
  sleep 30
  exit 1
fi

# Переходим в указанную папку
cd "$TARGET_DIR" || {
  echo "❌ Ошибка: Не удалось перейти в папку $TARGET_DIR"
  sleep 30
  exit 1
}

# Проверяем, находимся ли мы в репозитории Git
if [ ! -d .git ]; then
  echo "Ошибка: Эта папка не является репозиторием Git."
  sleep 30
  exit 1
fi

# Check if .git/index.lock exists and remove it
if [ -f ".git/index.lock" ]; then
    rm ".git/index.lock"
    echo "Removed existing .git/index.lock file"
fi


# Перебор всех элементов массива untracked_files
while IFS= read -r file; do

    echo "Обработка файла: $file"
    # Здесь можно выполнять какие-то действия с каждым файлом
    # Например, проверка размера, копирование, удаление и т.д.

    # Добавляем файл в Git
    git add "$file"

    # Получаем имя папки, в которой находится файл
    folder_name=$(basename "$(dirname "$file")")

    # Создаем коммит с именем папки
    git commit -m "$folder_name"

    # Отправляем изменения в удалённый репозиторий (в основную ветку)
    git push origin master  # todo ветку в параметр

done < <(find . -type f -size -50M -not -path "./.git/*" -not -path "./.idea/*" | shuf)


sleep 30
echo "✅ Все файлы (меньше 50МБ) добавлены, закоммичены и отправлены в репозиторий!"
# todo прогресс бар добавить
# todo ошибку пуша обрабатывать
# todo таймаут соединения с гитом увеличить