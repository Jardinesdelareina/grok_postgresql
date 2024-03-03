DELETE FROM users;

INSERT INTO users(
    email, 
    username, 
    gender, 
    date_joined, 
    first_name, 
    last_name
)
SELECT
    LEFT((md5(random()::text)), 10) || '@gmail.com',
    LEFT((md5(random()::text)), 8),
    CASE WHEN random() < 0.5 THEN 'M' ELSE 'F' END,
    TIMESTAMP '2021-01-01' - INTERVAL '1' DAY * FLOOR(random() * 3653),
    'fname' || LEFT(md5(random()::text), 8),
    'lname' || LEFT(md5(random()::text), 10)
FROM generate_series(1, 10000);