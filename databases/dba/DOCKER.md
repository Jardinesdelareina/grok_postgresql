# Docker

### Запуск и остановка

`docker compose up -d --build`     собрать и запустить в фоне

`docker compose up --build`        запустить с логами в терминал (для отладки)

`docker compose stop`              остановить (контейнеры остаются)

`docker compose start`             запустить остановленные

`docker compose restart`           перезапустить

`docker compose down`              остановить и удалить контейнеры + сети

`docker compose down -v`           + удалить volumes (данные!)


### Просмотр логов

`docker compose logs`              все логи

`docker compose logs -f`           следить в реальном времени

`docker compose logs -f server-1`  логи конкретного сервера

`docker compose logs --tail=100`   последние 100 строк

`docker compose logs --since 10m`  за последние 10 минут


### Статус и информация

`docker compose ps`                список контейнеров проекта

`docker compose ps -a`             включая остановленные

`docker ps`                        все запущенные контейнеры

`docker stats`                     CPU/RAM/сеть в реальном времени

`docker inspect server-1`          всё про контейнер (JSON)


### Вход внутрь контейнера

`docker exec -it server-1 bash`        зайти в shell

`docker exec -it server-1 hostname`    выполнить одну команду

`docker exec -u root server-1 bash`    зайти от root


### SSH-подключение

`ssh fueros@localhost -p 2221`         server-1, пароль: fueros

`ssh fueros@localhost -p 2222`         server-2, пароль: fueros


### Сборка и образы

`docker compose build`                 только собрать, без запуска

`docker compose build --no-cache`      собрать заново без кэша

`docker compose pull`                  обновить базовые образы

`docker images`                        список образов

`docker rmi <image>`                   удалить образ


### Пересборка одного сервера

`docker compose up -d --build server-1`   только server-1

`docker compose restart server-1`         только перезапустить

`docker compose logs -f server-1`         только его логи


### Очистка

`docker compose down`                  убрать контейнеры и сети

`docker system prune`                  удалить неиспользуемое (осторожно)

`docker system prune -a --volumes`     удалить всё неиспользуемое + volumes

`docker volume ls`                     список volumes


### Копирование файлов

`docker cp file.txt server-1:/home/fueros/`       хост -> контейнер

`docker cp server-1:/etc/ssh/sshd_config ./`      контейнер -> хост


### Проверка конфигов и сети

`docker compose config`                         проверить итоговый compose-файл

`docker network ls`                             список сетей

`docker network inspect dba_net-server-1`       детали сети (имя с префиксом проекта)


### Проверка SSH внутри контейнера

`docker exec server-1 service ssh status`

`docker exec server-1 grep PermitRootLogin /etc/ssh/sshd_config`

`docker exec server-1 ss -tlnp`             какие порты слушаются


### Изоляция (проверка, что серверы не видят друг друга)

`docker exec server-1 ping -c1 server-2`

ping: server-2: Name or service not known   <- ожидаемо