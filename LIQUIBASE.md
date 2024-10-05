# Liquibase

<div>
    <img src="https://github.com/devicons/devicon/blob/master/icons/liquibase/liquibase-original-wordmark.svg" width="40" height="40"/>&nbsp;
</div>

Liquibase - это инструмент для управления и отслеживания изменений в структуре базы данных. Он позволяет разработчикам автоматизировать процесс развертывания и управления изменениями в базе данных.

С помощью Liquibase разработчики могут создавать и обновлять схему базы данных, добавлять новые таблицы, столбцы, индексы, ключи, а также выполнять другие операции.

Liquibase использует файлы XML, YAML, JSON или SQL для описания изменений в базе данных. Эти файлы содержат информацию о том, какие изменения нужно применить, порядок их применения, условия выполнения и отката изменений.

Одним из основных преимуществ Liquibase является возможность отслеживания и контроля версий базы данных. Он позволяет разработчикам создавать файлы изменений, хранить их в репозитории версий и автоматически применять их к базе данных при необходимости.


[Документация Liquibase для PostgreSQL](https://docs.liquibase.com/start/tutorials/postgresql/postgresql.html)


### Установка Liquibase в Ubuntu

1. Установка Java:

`java -version`     Проверка наличия на сервере Java. Если нет, о следующий шаг - установка Java

`sudo apt install default-jre`


2. Импорт ключа Liquibase GPG и добавление репозитория Liquibase в apt:

`sudo wget -O- https://repo.liquibase.com/liquibase.asc | gpg --dearmor > liquibase-keyring.gpg && \
cat liquibase-keyring.gpg | sudo tee /usr/share/keyrings/liquibase-keyring.gpg > /dev/null && \
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/liquibase-keyring.gpg] https://repo.liquibase.com stable main' | sudo tee /etc/apt/sources.list.d/liquibase.list`


3. Установка Liquibase:

`sudo apt-get install liquibase`

`sudo apt-get install liquibase=4.29.2`     Установка определенной версии

4. Проверка версии:

`liquibase --version`


<b>Обновление Liquibase</b>

`sudo apt-get upgrade liquibase`


<b>Удаление Liquibase</b>

`sudo apt-get remove liquibase`


### Команды Liquibase

`liquibase init project`    Инициализация проекта (команда init доступна только в версиях 4.7.0 и выше)

`liquibase update`      Применить обновления к базе данных

Расширенная команда upgrade с флагами доступа к базе данных:

`liquibase --changeLogFile=changelog.xml --url=jdbc:postgresql://localhost:5432/dbname --username=username --password=password update`

Где:
* --changeLogFile - путь к файлу `changelog.xml` (источнику изменений)
* --url - адрес базы данных 
* --username - имя пользователя PostgreSQL
* --password - пароль
