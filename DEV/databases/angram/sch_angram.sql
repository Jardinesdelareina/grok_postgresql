---
--- Drop tables;
---
DROP TABLE messages;
DROP TABLE dialogs;
DROP TABLE followers;
DROP TABLE likes;
DROP TABLE comments;
DROP TABLE publications;
DROP TABLE users;


--
-- Name: users; 
-- Type: TABLE;
--
CREATE TABLE users
(
    user_id SERIAL PRIMARY KEY,
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
    is_superuser BOOLEAN DEFAULT ,

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);


--
-- Name: publications; 
-- Type: TABLE;
--
CREATE TABLE publications
(
    publication_id BIGSERIAL PRIMARY KEY,
    publication_image TEXT NOT NULL,
    publication_description VARCHAR(2000), 
    publication_created_at TIMESTAMPTZ DEFAULT NOW(),
    publication_updated_at TIMESTAMPTZ DEFAULT NOW(),
    publication_is_published BOOLEAN DEFAULT TRUE,
    fk_user_id INTEGER REFERENCES users(user_id)
);


--
-- Name: comments; 
-- Type: TABLE;
--
CREATE TABLE comments
(
    comment_id BIGSERIAL PRIMARY KEY,
    comment_text VARCHAR(500) NOT NULL,
    comment_created_at TIMESTAMPTZ DEFAULT NOW(),
    comment_updated_at TIMESTAMPTZ DEFAULT NOW(),
    comment_is_published BOOLEAN DEFAULT TRUE,
    fk_user_id INTEGER REFERENCES users(user_id),
    fk_publication_id INTEGER REFERENCES publications(publication_id)
);


--
-- Name: likes; 
-- Type: TABLE;
--
CREATE TABLE likes
(
    like_id BIGSERIAL PRIMARY KEY,
    fk_user_id INTEGER REFERENCES users(user_id),
    fk_publication_id INTEGER REFERENCES publications(publication_id)
);



--
-- Name: followers; 
-- Type: TABLE;
--
CREATE TABLE followers
(
    fk_folower_id INTEGER REFERENCES users(user_id),
    fk_folowing_id INTEGER REFERENCES users(user_id),
    follow_data TIMESTAMPTZ DEFAULT NOW()
);


--
-- Name: dialogs;
-- Type: TABLE;
--
CREATE TABLE dialogs
(
    dialog_id SERIAL PRIMARY KEY,
    fk_sender_id INTEGER REFERENCES users(user_id),
    fk_receiver_id INTEGER REFERENCES users(user_id)
);


--
-- Name: messages;
-- Type: TABLE;
--
CREATE TABLE messages
(
    message_id BIGSERIAL PRIMARY KEY,
    message_body TEXT,
    message_media TEXT,
    fk_dialog_id INTEGER REFERENCES dialogs(dialog_id),
    fk_sender_id INTEGER REFERENCES users(user_id)
);