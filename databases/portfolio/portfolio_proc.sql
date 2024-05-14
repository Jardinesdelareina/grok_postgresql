CREATE OR REPLACE PROCEDURE ms.create_user(
    input_email VARCHAR(255), 
    input_password VARCHAR(100)
    ) AS $$
    INSERT INTO ms.users(email, password)
    VALUES(input_email, crypt(input_password, gen_salt('md5')));
$$ LANGUAGE sql;


-- Создание портфеля
CREATE OR REPLACE PROCEDURE ms.create_portfolio(
    input_title VARCHAR(200), 
    input_is_published BOOLEAN,
    input_user_id INT
    ) AS $$
    INSERT INTO ms.portfolios(title, is_published, fk_user_id)
    VALUES(input_title, input_is_published, input_user_id);
$$ LANGUAGE sql;


-- Изменение параметров портфеля
CREATE OR REPLACE PROCEDURE ms.update_portfolio(
    input_portfolio_id INT,
    input_portfolio_title VARCHAR(200),
    input_is_published BOOLEAN
    ) AS $$
    UPDATE ms.portfolios
    SET title = input_portfolio_title,
        is_published = input_is_published
    WHERE id = input_portfolio_id;
$$ LANGUAGE sql;


-- Создание транзакции
CREATE OR REPLACE PROCEDURE ms.create_transaction(
    input_action_type VARCHAR(4),
    input_quantity REAL,
    input_portfolio_id INT,
    input_currency_id INT
    ) AS $$
    INSERT INTO ms.transactions(action_type, quantity, fk_portfolio_id, fk_currency_id)
    VALUES(input_action_type, input_quantity, input_portfolio_id, input_currency_id);
$$ LANGUAGE sql;