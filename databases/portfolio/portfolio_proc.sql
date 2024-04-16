-- Получение последней цены закрытия определенного тикера
CREATE OR REPLACE PROCEDURE qts.get_price(input_symbol VARCHAR(10)) AS $$
    SELECT m_close AS last_price 
    FROM qts.quotes 
    WHERE m_symbol = input_symbol
    ORDER BY m_time DESC 
    LIMIT 1;
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


-- Вывод портфелей пользователя
CREATE OR REPLACE PROCEDURE ms.get_portfolio(input_user_id INT) AS $$
    SELECT id, title, is_published
    FROM ms.portfolios
    WHERE fk_user_id = input_user_id;
$$ LANGUAGE sql;


-- Вывод валют определенного портфеля
CREATE OR REPLACE PROCEDURE ms.get_currencies_portfolio(input_portfolio_id INT) AS $$
    SELECT DISTINCT ms.currencies.id, symbol description
    FROM ms.currencies
    JOIN ms.transactions ON ms.transactions.fk_currency_id = ms.currencies.id
    WHERE fk_portfolio_id = input_portfolio_id
    ORDER BY symbol;
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