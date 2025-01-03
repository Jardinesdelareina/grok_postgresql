#!/bin/bash

# Загрузка переменных окружения из .env файла
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Сборка Docker образа
docker build -t $IMAGE_NAME .

# Запуск контейнера
docker run --rm --name $CONTAINER_NAME \
 -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
 -e POSTGRES_USER=$POSTGRES_USER \
 -d $IMAGE_NAME

# Ожидание запуска контейнера
sleep 5

# Подключение к psql в контейнере
docker exec -it $CONTAINER_NAME psql -U $POSTGRES_USER