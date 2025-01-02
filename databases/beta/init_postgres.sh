#!/bin/bash

# Загрузка переменных окружения из .env файла
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Сборка Docker образ
docker build -t $IMAGE_NAME .

# Запуск контейнер
docker run --name $CONTAINER_NAME \
 -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
 -e POSTGRES_USER=$POSTGRES_USER \
 -d $IMAGE_NAME

# Ожидание запуска контейнера
sleep 15

# Подключаемся к psql в контейнере
docker exec -it $CONTAINER_NAME psql -U $POSTGRES_USER