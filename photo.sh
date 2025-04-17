#!/bin/bash

# пример вызова скрипта:  
#bash photo.sh --folder="/d/PHOTO" --max-size=50M --branch=master
#bash photo.sh --folder="/d/PHOTO" --search-folder="Домашние" --max-size=50M --branch=master

# В начале скрипта
export LANG=en_US.UTF-8

# Инициализируем переменные
TARGET_DIR=""
MAX_SIZE="50M"
BRANCH="master"
SEARCH_FOLDER=""

# Парсим аргументы командной строки
while [ $# -gt 0 ]; do
    case "$1" in
        --folder=*)
            TARGET_DIR="${1#*=}"
            ;;
        --max-size=*)
            MAX_SIZE="${1#*=}"
            ;;
        --branch=*)
            BRANCH="${1#*=}"
            ;;
        --search-folder=*)
            SEARCH_FOLDER="${1#*=}"
            ;;
        --help)
            echo "Использование: bash photo.sh --folder=\"/путь/к/папке\" [--max-size=50M] [--branch=master]"
            exit 0
            ;;
        *)
            echo "Неизвестный параметр: $1"
            echo "Используйте --help для справки"
            exit 1
            ;;
    esac
    shift
done

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

# Формируем путь для поиска
SEARCH_PATH="."
if [ -n "$SEARCH_FOLDER" ]; then
    SEARCH_PATH="./$SEARCH_FOLDER"
    # Проверяем существование папки для поиска
    if [ ! -d "$SEARCH_PATH" ]; then
        echo "Ошибка: Папка для поиска $SEARCH_FOLDER не существует!"
        exit 1
    fi
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

    # Отправляем изменения в удалённый репозиторий
    git push origin $BRANCH

done < <(find "$SEARCH_PATH" -type f -size -$MAX_SIZE -not -path "./.git/*" -not -path "./.idea/*" | shuf)


sleep 30
echo "✅ Все файлы (меньше $MAX_SIZE) добавлены, закоммичены и отправлены в репозиторий!"
# todo прогресс бар добавить
# todo ошибку пуша обрабатывать
# todo таймаут соединения с гитом увеличить