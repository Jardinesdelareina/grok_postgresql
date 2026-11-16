# Linux

### Кто я и где я

`whoami`                  текущий пользователь

`id`                      uid, gid, группы

`hostname`                имя сервера

`pwd`                     текущая директория

`uname -a`                версия ядра

`cat /etc/os-release`     версия Ubuntu

`uptime`                  сколько работает, load average

`date`                    дата/время


### Навигация по файловой системе

`ls -la`                  список файлов с правами и скрытыми

`cd /etc`                 перейти в директорию

`cd ~`                    в домашнюю

`cd -`                    в предыдущую

`pwd`                     где я

`tree /etc -L 2`          дерево (если установлен tree)


### Файлы и директории

`touch file.txt`          создать пустой файл

`mkdir dir`               создать директорию

`mkdir -p a/b/c`          создать вложенные

`cp file1 file2`          копировать

`cp -r dir1 dir2`         копировать рекурсивно

`mv file1 file2`          переместить/переименовать

`rm file`                 удалить файл

`rm -r dir`               удалить директорию

`rm -rf dir`              удалить без вопросов (осторожно!)

`ln -s target link`       символическая ссылка


### Просмотр файлов

`cat file`                весь файл

`less file`               постранично (q — выход)

`head -n 20 file`         первые 20 строк

`tail -n 20 file`         последние 20 строк

`tail -f /var/log/syslog` следить за файлом

`grep "pattern" file`     поиск по содержимому

`grep -r "pattern" /etc`  рекурсивный поиск


### Права доступа

`ls -l file`              -rw-r--r-- 1 fueros fueros ...

`chmod 644 file`          rw-r--r--

`chmod 755 script.sh`     rwxr-xr-x

`chmod +x script.sh`      сделать исполняемым

`chown fueros file`       сменить владельца (нужен sudo)

`chown fueros:fueros file`

`chgrp group file`        сменить группу


### sudo — администрирование

`sudo command`            выполнить от root

`sudo -i`                 войти в root-shell

`sudo -u user command`    выполнить от другого пользователя

`sudo -l`                 что мне разрешено


### Пользователи и группы

`sudo useradd -m -s /bin/bash newuser`      создать пользователя с домашней

`sudo passwd newuser`                       задать пароль

`sudo usermod -aG sudo newuser`             добавить в sudo

`sudo userdel -r newuser`                   удалить с домашней

`groups fueros`                             группы пользователя

`cat /etc/passwd`                           список пользователей

`cat /etc/group`                            список групп

`last`                                      кто и когда заходил

`who`                                       кто сейчас в системе


### Пакеты (apt) (на примере nginx)

`sudo apt update`                 обновить список пакетов

`sudo apt upgrade -y`             обновить установленные

`sudo apt install nginx`          установить

`sudo apt remove nginx`           удалить (конфиги остаются)

`sudo apt purge nginx`            удалить с конфигами

`sudo apt autoremove`             удалить ненужные зависимости

`apt search nginx`                поиск пакета

`apt show nginx`                  информация о пакете

`dpkg -l`                         список установленных

`dpkg -L nginx`                   какие файлы у пакета


### Сервисы

`service ssh status`              статус

`service ssh start`               запустить

`service ssh stop`                остановить

`service ssh restart`             перезапустить

`service --status-all`            все сервисы


### Процессы

`ps aux`                          все процессы

`ps aux | grep ssh`               найти по имени

`top`                             живой монитор (q — выход)

`htop`                            удобнее (если установлен)

`kill PID`                        мягко завершить процесс

`kill -9 PID`                     жёстко убить

`pkill -f pattern`                убить по шаблону

`pgrep -f pattern`                найти PID по шаблону


### Сеть

`ip a`                            IP-адреса интерфейсов

`ip r`                            маршруты

`ss -tlnp`                        слушающие порты

`ss -tunap`                       все соединения

`ping -c3 google.com`             проверить связность

`curl -I https://example.com`     HTTP-запрос

`wget https://example.com/file`   скачать файл

`dig google.com`                  DNS-запрос (нужен dnsutils)

`hostname -I`                     IP-адреса хоста


### Диски и память

`df -h`                           занятость дисков

`du -sh /var/log`                 размер директории

`du -sh * | sort -h`              размеры в текущей папке

`free -h`                         память

`lsblk`                           блочные устройства

`mount`                           смонтированные ФС


### Логи

`tail -f /var/log/syslog`         системный лог

`tail -f /var/log/auth.log`       логи аутентификации (SSH, sudo)

`dmesg | tail`                    лог ядра


### Архивы

`tar -czf archive.tar.gz dir/`    создать архив

`tar -xzf archive.tar.gz`         распаковать

`tar -tzf archive.tar.gz`         посмотреть содержимое

`zip -r archive.zip dir/`         zip

`unzip archive.zip`               unzip


### Поиск

`find /etc -name "*.conf"`                  найти файлы по имени

`find /var/log -type f -mtime -1`           изменённые за сутки

`find / -size +100M 2>/dev/null`            файлы > 100 МБ

`grep -r "PermitRootLogin" /etc/ssh/`       поиск по содержимому

`which nginx`                               где бинарник

`whereis nginx`                             бинарник + man + конфиги


### Редактирование файлов

`nano file`                       простой редактор (Ctrl+O — сохранить, Ctrl+X — выйти)

`vim file`                        vim (i — вставка, Esc :wq — сохранить и выйти)


### Планировщик (cron)

`crontab -l`                      список задач

`crontab -e`                      редактировать


### SSH-ключи и доступ

`ssh-keygen -t ed25519 -C "comment"`          сгенерировать ключ

`ssh-copy-id user@host`                       скопировать публичный ключ на сервер

`cat ~/.ssh/authorized_keys`                  какие ключи разрешены

`chmod 700 ~/.ssh`                            права на директорию

`chmod 600 ~/.ssh/authorized_keys`            права на файл


### Полезные однострочники

`ps aux --sort=-%cpu | head -11`                     топ-10 процессов по CPU

`du -sh /var/* 2>/dev/null | sort -h | tail -10`     топ-10 директорий по размеру

`find / -type f -size +1G 2>/dev/null`               все файлы больше 1 ГБ

`ss -tlnp | grep :22`                                кто слушает порт 22

`grep "Failed password" /var/log/auth.log | tail`    последние неудачные SSH

`service ssh status || echo "SSH DOWN"`              проверить, что сервис жив


### Типичные задачи

Поставить и запустить nginx

`sudo apt update`

`sudo apt install -y nginx`

`service nginx start`

`service nginx status`

`curl -I http://localhost`

Создать пользователя с sudo

`sudo useradd -m -s /bin/bash deploy`

`sudo passwd deploy`

`sudo usermod -aG sudo deploy`

Посмотреть, кто заходил по SSH

`last | head`

`grep "Accepted" /var/log/auth.log | tail`

Проверить, не кончилось ли место

`df -h`

`du -sh /var/* | sort -h | tail`

Найти и убить процесс, занявший порт

`ss -tlnp | grep :8080`

`sudo kill <PID>`

Забэкапить директорию

`tar -czf /home/fueros/backup-$(date +%F).tar.gz /etc/nginx`


### Чего в контейнере нет

`systemctl`         нет systemd как PID 1

`reboot/shutdown`   контейнер не «перезагружается», его пересоздают

`journalctl`        нет systemd-journald

`ufw/iptables`      сетевые правила — на хосте Docker

`mount`             монтирование — на хосте через volumes:


### Проверка «всё ли ок» после входа

`whoami`                  fueros

`id`                      в группе sudo

`sudo -n true && echo "sudo OK"`

`df -h /`                 есть место

`free -h`                 есть память

`service ssh status`      sshd работает

`ss -tlnp`                порт 22 слушается