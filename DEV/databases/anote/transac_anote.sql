BEGIN;

UPDATE users;
SET first_name = 'update_test_user';
WHERE user_id = 1;

SELECT * FROM users WHERE user_id = 1;

COMMIT;