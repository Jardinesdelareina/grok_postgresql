DROP DATABASE test_db;
CREATE DATABASE test_db 
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;