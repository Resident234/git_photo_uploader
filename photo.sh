#!/bin/bash

# пример вызова скрипта:  
#bash photo.sh "/d/PHOTO"

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

# Получаем список файлов, которые уже в индексе Git (в массив)
mapfile -t indexed_files < <(git ls-files)
echo "Файлов в индексе git: ${#indexed_files[@]}"

# Проверим, что в массиве
#for file in "${indexed_files[@]}"; do
#    echo "files in index: $file"
#done

sleep 30

: <<'COMMENT'
BLG/DSC04482.JPG
BLG/DSC04482.JPG
BLG/DSC04482.JPG
BLG/DSC04482.JPG
BLG/DSC04482.JPG
BLG/DSC04482.JPG
BLG/DSC04482.JPG
COMMENT


# Declare an array to hold file paths
declare -a files

# Use find to locate files smaller than 50MB and iterate over them
while IFS= read -r file; do
    echo "Найден файл $file"
    files+=("$file")
done < <(find . -type f -size -50M -not -path "./.git/*")


: <<'COMMENT'
./BLG/DSC04482.JPG
./BLG/DSC04482.JPG
./BLG/DSC04482.JPG
./BLG/DSC04482.JPG
./BLG/DSC04482.JPG
./BLG/DSC04482.JPG
./BLG/DSC04482.JPG
COMMENT

# Iterate over the array and remove the "./" prefix
for i in "${!files[@]}"; do
    echo "Удаление ./ из $i"
    files[$i]="${files[$i]#./}"
done

#for file in "${files[@]}"; do
#    echo "files all: $file"
#done

# Array to hold the difference
diff_files=()

# Find elements in 'files' that are not in 'indexed_files'
for file in "${files[@]}"; do
    echo "Поиск файла $file в индексе"
    if [[ ! " ${indexed_files[@]} " =~ " ${file} " ]]; then
        diff_files+=("$file")
    fi
done

# Print the difference
#echo "Files not indexed:"
#for diff in "${diff_files[@]}"; do
#    echo "diff $diff"
#done

# Add "./" prefix to each element in diff_files
for i in "${!diff_files[@]}"; do
    echo "Добавление ./ к $i"
    diff_files[$i]="./${diff_files[$i]}"
done

# Overwrite files with diff_files
files=("${diff_files[@]}")

# Check if .git/index.lock exists and remove it
if [ -f ".git/index.lock" ]; then
    rm ".git/index.lock"
    echo "Removed existing .git/index.lock file"
fi



# Проходимся по массиву
for file in "${files[@]}"; do

  # Добавляем файл в Git
  git add "$file"

  # Получаем имя папки, в которой находится файл
  folder_name=$(basename "$(dirname "$file")")

  # Создаем коммит с именем папки
  git commit -m "$folder_name"

  # Отправляем изменения в удалённый репозиторий (в основную ветку)
  git push origin master  # todo ветку в параметр

done

sleep 30
echo "✅ Все файлы (меньше 50МБ) добавлены, закоммичены и отправлены в репозиторий!"
# todo прогресс бар добавить
# todo ошибку пуша обрабатывать
# todo таймаут соединения с гитом увеличить