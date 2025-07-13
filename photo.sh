#!/bin/bash

# пример вызова скрипта:  
#bash photo.sh --folder="/h/PHOTO" --max-size=50M --branch=master
#bash photo.sh --folder="/d/PHOTO" --search-folder="Домашние" --max-size=50M --branch=master

# В начале скрипта
export LANG=en_US.UTF-8


# Функция для отображения прогресс-бара
show_progress() {
    local current=$1
    local total=$2
    local width=50  # ширина прогресс-бара
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    # Создаем строку прогресса
    printf "\rПрогресс: ["
    printf "%${completed}s" | tr ' ' '#'
    printf "%$((width - completed))s" | tr ' ' '-'
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
}

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

untracked_files=()



# Получаем общее количество файлов для обработки


while IFS= read -r file; do

    untracked_files+=("$file")

done < <(find "$SEARCH_PATH" -type f -size -$MAX_SIZE -not -path "./.git/*" -not -path "./.idea/*" | shuf)

total_files=${#untracked_files[@]}
current_file=0

echo "Найдено файлов для обработки: $total_files"


# 2. Перебор всех найденных неиндексированных файлов из массива
for file in "${untracked_files[@]}"; do

    # while это бесконечный цикл
    # в этом цикле проверять последнюю активность пользователя в системе. Если пользователь был активен менее 5 минут назад, то делать паузу на 5 минут, если был активен более 5 минут назад, то выхоить из цикла
    while true; do
        # Получаем HTML страницы
        html=$(curl -s "https://github.com/Resident234Photo")

        # Если найдено слово "stop", делаем паузу 5 минут
        if echo "$html" | grep -qi "stop"; then
            echo "Обнаружено слово 'stop' в HTML. Пауза 5 минут."
            sleep 300
        else
            break
        fi
    done

    ((current_file_num++))

    # Показываем прогресс
    show_progress "$current_file_num" "$total_files" "$file"
    
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

done

sleep 30
echo "✅ Все файлы (меньше $MAX_SIZE) добавлены, закоммичены и отправлены в репозиторий!"
# todo ошибку пуша обрабатывать
# todo таймаут соединения с гитом увеличить
