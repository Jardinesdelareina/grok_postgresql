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