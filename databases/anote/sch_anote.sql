---
--- Drop tables
---

DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS articles;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;


--
-- Name: users; 
-- Type: TABLE;
--
CREATE TABLE users
(
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(32) UNIQUE NOT NULL,
    first_name VARCHAR(32) NOT NULL,
    middle_name VARCHAR(32) NOT NULL,
    last_name VARCHAR(32) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone SMALLINT UNIQUE,
    date_of_birdth DATE,
    about TEXT,
    avatar TEXT,
    is_superuser BOOLEAN,

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);

CREATE INDEX idx_users ON users (username, email);


--
-- Name: categories; 
-- Type: TABLE; 
--
CREATE TABLE categories
(
    category_id SMALLSERIAL PRIMARY KEY,
    category_title VARCHAR(32) UNIQUE NOT NULL
);


--
-- Name: articles; 
-- Type: TABLE;
--
CREATE TABLE articles
(
    article_id SERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_published BOOLEAN,
    article_text TEXT NOT NULL,
    article_image TEXT,
    fk_user_id INTEGER REFERENCES users(user_id),
    fk_category_id SMALLINT REFERENCES categories(category_id)
);

CREATE INDEX idx_articles ON articles (created_at);


--
-- Name: comments; 
-- Type: TABLE;
--
CREATE TABLE comments
(
    comment_id SERIAL PRIMARY KEY,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT false,
    fk_user_id INTEGER REFERENCES users(user_id),
    fk_article_id INTEGER REFERENCES articles(article_id)
);

CREATE INDEX idx_comments ON comments (created_at);