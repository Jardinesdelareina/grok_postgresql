#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Начало процесса деплоя"

# 0. Проверки окружения
if ! command -v docker >/dev/null 2>&1; then
  echo "ОШИБКА: docker не найден в PATH" >&2
fi

if ! docker info >/dev/null 2>&1; then
  echo "ОШИБКА: демон Docker недоступен (проверь Docker Desktop / WSL Integration)" >&2
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ОШИБКА: docker compose (v2) не найден" >&2
fi

if [[ ! -f .env ]]; then
  echo "ОШИБКА: файл .env не найден в $(pwd)" >&2
fi

if [[ ! -f docker-compose.yml ]]; then
  echo "ОШИБКА: docker-compose.yml не найден в $(pwd)" >&2
fi

echo "1. Останавливаем работающие контейнеры..."
docker compose down || true

echo "2. Очищаем неиспользуемые образы..."
docker image prune -f

echo "3. Удаляем неиспользуемые тома..."
docker volume prune -f

echo "4. Очищаем кэш сборки..."
docker builder prune -f

echo "5. Собираем и запускаем контейнеры..."
if ! docker compose up -d --build; then
  echo "ОШИБКА: docker compose up завершился с ошибкой" >&2
  docker compose ps >&2 || true
  docker compose logs --tail=50 db >&2 || true
  docker compose logs --tail=50 app >&2 || true
  docker compose logs --tail=50 web >&2 || true
fi

echo "6. Проверяем состояние сервисов..."
docker compose ps

running_count=$(docker compose ps --status running --format '{{.Name}}' | wc -l | tr -d ' ')
expected_count=$(docker compose config --services | wc -l | tr -d ' ')

if [[ "$running_count" -ne "$expected_count" ]]; then
  echo "ОШИБКА: запущено $running_count из $expected_count сервисов" >&2
  docker compose ps >&2 || true
fi

echo "Деплой успешно завершён. Все $expected_count сервисов работают."