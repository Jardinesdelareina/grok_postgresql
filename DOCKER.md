# Docker

<div>
    <img src="https://github.com/devicons/devicon/blob/master/icons/docker/docker-original-wordmark.svg" width="40" height="40"/>&nbsp;
</div>


### Установка Docker в Ubuntu 22.04

Если Docker был установлен в ОС ранее, нужно произвести <b>удаление</b> всех конфликтующих пакетов:

```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```


<b>Установка:</b>

<em>Добавить официальный ключ GPG Docker:</em>
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

<em>Добавить репозиторий в источники Apt:</em>
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```


`sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`   установка последней версии Docker

`sudo docker run hello-world`   запуск образа `hello-world` (проверка, что установка Docker Engine прошла успешно)


### Установка Docker Desktop

1. [Загрузить](https://desktop.docker.com/linux/main/amd64/157355/docker-desktop-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64&_gl=1*1oh7zxu*_gcl_au*NTM1NTMxNTY4LjE3MjExMzgyMTc.*_ga*MjgxNzE1NjM0LjE3MjExMzgxMTY.*_ga_XJWPQMJYHQ*MTcyMTEzODExNi4xLjEuMTcyMTE0MDcwNy4yNy4wLjA.) последнюю версию DEB-пакета;

2. Установить пакет (нужно находиться с DEB-пакетом в одной директории):
```bash
sudo apt-get update
sudo apt-get install ./docker-desktop-amd64.deb
```


### Установка и настройка PostgreSQL в Docker

`sudo apt-cache depends postgresql-14`  просмотр зависимостей PostgreSQL

`sudo systemctl status docker`  проверка статуса Docker в ОС

`sudo systemctl start docker`   запуск процесса Docker

`sudo systemctl stop docker`    остановка процесса Docker

`sudo systemctl restart docker`   рестарт Docker

`sudo systemctl enable docker`    включение автозапуска Docker в ОС

`sudo systemctl disable docker`   отключение автозапуска Docker

`sudo docker pull postgres`   получение из Docker Hub готового образа PostgreSQL

За пределами жизненного цикла контейнера не остается каких-либо данных. Поэтому на файловой системе сервера необходимо создать каталог для хранения данных, которые будут появятся в процессе работы экземпляра PostgreSQL: `mkdir -p $HOME/docker/volumes/postgres`

`sudo docker run --rm --name fueros_pg -e POSTGRES_PASSWORD=fueros -e POSTGRES_USER=fueros -e POSTGRES_DB=fueros -d -p 5432:5432 -v $HOME/docker/volumes/postgres:/var/lib/postgresql/data postgres`   запуск контейнера PostgreSQL
* <b>--rm</b> организовывает автоматическое удаление файловой системы контейнера после его остановки
* <b>--name</b> устанавливает имя контейнера
* <b>-e</b> задает переменные окружения
* <b>-d</b> задает запуск контейнера в фоновом режиме
* <b>-p</b> задает привязкку внутреннего порта сервера к порту контейнера
* <b>-v</b> задает точку монтирования каталога данных на сервере к каталогу данных в контейнере

<em>Команда запускает клиент psql в контейнере.</em>


`sudo docker stop fueros_pg`    остановка контейнера fueros_pg


### Команды Docker

<em>Команды применяются вместе с `sudo docker`</em>

`pull <образ>`  забрать образ из Docker Hub

`run`   создать контейнер
* `--name`  задать имя контейнеру
* `-d`  detached mode (открепить терминал от контейнера, фоновый режим)

`ps`  вывести список запущенных контейнеров (`-a` дает расширенную информацию)

`rm <id контейнера>`  удалить контейнер  

`rmi <id образа>`   удалить образ

`stop`  остановить контейнер

`images`  вывести список доступных локально образов

`search <образ>`  искать доступные в сети образы


### Docker Compose

`sudo apt install docker-compose`   установить docker-compose

Создается файл `docker-compose.yml` следующего содержания:

```
services:

  db:
    image: postgres:14
    restart: always
    container_name: database
    env_file:
      - ./.env
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - .:/docker-entrypoint-initdb.d
```

В volumes должен находиться sql-файл, инициализирующий кластер PostgreSQL. Переменные окружения читаются из файла `.env`.

`sudo docker compose up -d`   запуск контейнера в фоновом режиме

`sudo docker compose up --build`   сборка контейнера из образа и его запуск (--force-recreate пересоздание образа после остановки контейнера)

`sudo docker exec -it <ID контейнера> bash`   вход в терминал работающего контейнера

`sudo docker compose stop`    остановка контейнера

`sudo docker-compose down --rmi all`  остановка контейнеров и удаление образов, связанных с ними