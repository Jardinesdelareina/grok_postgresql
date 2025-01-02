# Docker

<div>
    <img src="https://github.com/devicons/devicon/blob/master/icons/docker/docker-original-wordmark.svg" width="40" height="40"/>&nbsp;
</div>


### Основные концепции Docker

* Образ (Image): Это шаблон, из которого создаются контейнеры. Образ содержит все необходимые зависимости для приложения.

* Контейнер (Container): Это экземпляр образа, который выполняется в изолированной среде. Контейнеры могут быть запущены, остановлены, удалены и перемещены.

* Dockerfile: Это текстовый файл, содержащий инструкции для создания образа. В нем описываются все зависимости и команды, необходимые для настройки окружения.

* Docker Hub: Это облачный реестр, где можно хранить и делиться образами. Вы можете загружать свои образы и загружать образы других пользователей.


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


#### Установка Docker Desktop

1. [Загрузить](https://desktop.docker.com/linux/main/amd64/157355/docker-desktop-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64&_gl=1*1oh7zxu*_gcl_au*NTM1NTMxNTY4LjE3MjExMzgyMTc.*_ga*MjgxNzE1NjM0LjE3MjExMzgxMTY.*_ga_XJWPQMJYHQ*MTcyMTEzODExNi4xLjEuMTcyMTE0MDcwNy4yNy4wLjA.) последнюю версию DEB-пакета;

2. Установить пакет (нужно находиться с DEB-пакетом в одной директории):
```bash
sudo apt-get update
sudo apt-get install ./docker-desktop-amd64.deb
```


### Установка Docker в Windows 11

`wsl --install`   установка WSL 2, по-умолчанию, установится WSL2 с GUI и Ubuntu

Далее установка учетных данных в среде Linux (ввести логин и пароль)

`sudo apt-get update`   обновление пакетов в Ubuntu

`hostnamectl`   проверка версии дистрибутива


Далее, нужно [скачать установочный файл с официального сайта](https://docs.docker.com/desktop/setup/install/windows-install/), установить Docker и перезагрузить компьютер. 


### Установка и настройка PostgreSQL в Docker

`sudo apt-cache depends postgresql-14`  просмотр зависимостей PostgreSQL

`sudo systemctl status docker`  проверка статуса Docker в ОС

`sudo systemctl start docker`   запуск процесса Docker

`sudo systemctl stop docker`    остановка процесса Docker

`sudo systemctl restart docker`   рестарт Docker

`sudo systemctl enable docker`    включение автозапуска Docker в ОС

`sudo systemctl disable docker`   отключение автозапуска Docker

`sudo docker pull postgres`   получение из Docker Hub готового образа PostgreSQL


#### Запуск контейнера с PostgreSQL

Для использования PostgreSQL в контейнере Docker обычно не требуется создавать 
собственный Dockerfile, так как существует официальный образ PostgreSQL, который можно использовать. 
Однако, если нужно создать свой Dockerfile, это может выглядеть следующим образом:

```Dockerfile
# Официальный образ PostgreSQL
FROM postgres:17

# Установка дополнительных зависимостей или настроек, если необходимо

# Копирование скриптов инициализации (если есть)
COPY init.sql /docker-entrypoint-initdb.d/

# Переменные окружения (по желанию)
ENV POSTGRES_DB=db_name
ENV POSTGRES_USER=db_user
ENV POSTGRES_PASSWORD=db_password
```

`docker build -t image_name .`  сборка образа с названием image_name на основе Dockerfile из текущего каталога

`docker run --name cont_name -e POSTGRES_PASSWORD=password -d image_name`   поднятие контейнера cont_name на основе образа image_name с передачей в переменной окружения пароля для PostgreSQL


#### Запуск контейнера с PostgreSQL без Dockerfile:

`docker run --rm --name postgres_test -e POSTGRES_PASSWORD=postgres_pass -e POSTGRES_USER=postgres -e POSTGRES_DB=postgres -d -p 5432:5432 -v pgdata:/var/lib/postgresql/data postgres`
* <b>--name</b> устанавливает имя контейнера
* <b>-e</b> задает переменные окружения
* <b>-d</b> задает запуск контейнера в фоновом режиме
* <b>-p</b> задает привязкку внутреннего порта сервера к порту контейнера
* <b>-v</b> задает точку монтирования каталога данных на сервере к каталогу данных в контейнере

`docker exec -it <ID/имя контейнера> psql -U postgres -d postgres`   активация psql в контейнере

`docker stop postgres`    остановка контейнера postgres


Запуск PostgreSQL в Docker и вход в psql:
```bash
docker run --name postgres -e POSTGRES_DB=postgres -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:latest
docker exec -it postgres psql -U postgres -d postgres
```


#### Сохранение данных между запусками контейнера

По умолчанию, если контейнер останавли вается или удаляется, все данные в нем теряются. 
Чтобы сохранить данные между запусками, используются тома Docker. 

`-v pgdata:/var/lib/postgresql/data` cоздает или использует том pgdata для хранения данных PostgreSQL.
Все данные базы данных будут храниться в этом томе, даже если контейнер будет остановлен или удален.


### Команды Docker

<em>Команды применяются вместе с `docker`</em>

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

Docker Compose позволяет:

* Определять многоконтейнерные приложения с помощью простого текстового файла (обычно docker-compose.yml).

* Запускать все контейнеры с одной командой.

* Легко управлять жизненным циклом контейнеров (запуск, остановка, удаление).

* Настраивать сети и тома для взаимодействия между контейнерами.

Docker Compose обычно устанавливается вместе с Docker Desktop на Windows и macOS. Для Linux может понадобиться установить его отдельно.

`docker-compose --version`  проверить версию Docker Compose

`sudo apt install docker-compose`   установить Docker Compose

Файл `docker-compose.yml` используется для описания конфигурации приложения. Вот основные элементы, которые могут быть включены в этот файл:

* version: Версия синтаксиса Compose.

* services: Определяет контейнеры (сервисы), которые будут запущены.

* networks: Определяет сети, используемые контейнерами.

* volumes: Определяет тома для хранения данных.

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
  
  etl:
    build: ./
    container_name: df_etl
    command: ["python3", "main.py"]
    restart: always
    volumes:
      - .:/app
    env_file:
      - ./.env
```

В volumes должен находиться sql-файл, инициализирующий кластер PostgreSQL. Переменные окружения читаются из файла `.env`.

`docker compose up -d`   запуск контейнера в фоновом режиме

`docker compose up --build`   сборка контейнера из образа и его запуск (--force-recreate пересоздание образа после остановки контейнера)

`docker exec -it <ID/имя контейнера> bash`   вход в терминал работающего контейнера

`docker compose down --rmi all`  остановка контейнеров и удаление образов, связанных с ними


