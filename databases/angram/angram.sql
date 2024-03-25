\connect postgres

DROP DATABASE IF EXISTS angram;
CREATE DATABASE angram;

\connect angram;

DROP SCHEMA IF EXISTS angram_v1 CASCADE;
CREATE SCHEMA angram_v1;


--
-- Пользователи
--
CREATE TABLE angram_v1.users
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(32) UNIQUE NOT NULL,
    gender VARCHAR(1) CHECK (gender IN ('M', 'F')) DEFAULT 'M',
    date_joined TIMESTAMPTZ DEFAULT NOW(),
    first_name VARCHAR(32) NOT NULL,
    last_name VARCHAR(32) NOT NULL,
    phone SMALLINT UNIQUE,
    date_of_birdth DATE,
    about TEXT,
    avatar TEXT,
    is_superuser BOOLEAN DEFAULT FALSE,

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);

CREATE INDEX idx_user
ON angram_v1.users (first_name, last_name);


--
-- Публикации
--
CREATE TABLE angram_v1.publications
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    image TEXT NOT NULL,
    description VARCHAR(2000), 
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_published BOOLEAN DEFAULT TRUE,
    fk_user_id INT REFERENCES angram_v1.users(id)
);


--
-- Комментарии
--
CREATE TABLE angram_v1.comments
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    text VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_published BOOLEAN DEFAULT TRUE,
    fk_user_id INT REFERENCES angram_v1.users(id),
    fk_publication_id INT REFERENCES angram_v1.publications(id)
);


--
-- Лайки
--
CREATE TABLE angram_v1.likes
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id INT REFERENCES angram_v1.users(id),
    fk_publication_id INT REFERENCES angram_v1.publications(id)
);


--
-- Подписчики
--
CREATE TABLE angram_v1.followers
(
    fk_folower_id INT REFERENCES angram_v1.users(id),
    fk_folowing_id INT REFERENCES angram_v1.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);


--
-- Диалоги
--
CREATE TABLE angram_v1.dialogs
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_sender_id INT REFERENCES angram_v1.users(id),
    fk_receiver_id INT REFERENCES angram_v1.users(id)
);


--
-- Личные сообщения
--
CREATE TABLE angram_v1.messages
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    body TEXT,
    media TEXT,
    fk_dialog_id INT REFERENCES angram_v1.dialogs(id),
    fk_sender_id INT REFERENCES angram_v1.users(id)
);