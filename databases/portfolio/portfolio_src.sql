-- Получение последней цены закрытия определенного тикера
CREATE OR REPLACE FUNCTION qts.get_price(input_symbol VARCHAR(10)) RETURNS REAL AS $$
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


-- Вывод списка портфелей определенного пользователя
CREATE OR REPLACE FUNCTION ms.get_portfolios(input_user_id INT) 
RETURNS SETOF ms.portfolios AS $$
    BEGIN
        RETURN QUERY SELECT id, title, balance, is_published, fk_user_id
                    FROM ms.portfolios 
                    WHERE fk_user_id = input_user_id;
    END;
$$ LANGUAGE plpgsql;


-- Вывод криптовалют определенного портфеля
CREATE OR REPLACE FUNCTION ms.get_currencies_portfolio(input_portfolio_id INT) 
RETURNS SETOF ms.currencies AS $$
    BEGIN
	    RETURN QUERY SELECT DISTINCT ms.currencies.id, symbol, description
                FROM ms.currencies
                JOIN ms.transactions ON ms.transactions.fk_currency_id = ms.currencies.id
                WHERE fk_portfolio_id = input_portfolio_id
                ORDER BY id;
	END;
$$ LANGUAGE plpgsql;


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


-- Расчет объема транзакции в usdt
CREATE OR REPLACE FUNCTION ms.get_value_transaction(input_transaction_id BIGINT) 
RETURNS REAL AS $$
DECLARE
    qty_transaction REAL;
BEGIN
    WITH qty_currency AS (
        SELECT quantity, ms.transactions.fk_currency_id AS curr
        FROM ms.transactions 
        JOIN ms.portfolios ON ms.transactions.id = ms.portfolios.id
        WHERE ms.transactions.id = input_transaction_id
    )
    SELECT INTO qty_transaction
    CASE curr
        WHEN 1 THEN (SELECT qts.get_price('btcusdt'))
        WHEN 2 THEN (SELECT qts.get_price('ethusdt'))
        WHEN 3 THEN (SELECT qts.get_price('solusdt'))
        WHEN 4 THEN (SELECT qts.get_price('xrpusdt'))
        WHEN 5 THEN (SELECT qts.get_price('adausdt'))
        WHEN 6 THEN (SELECT qts.get_price('avaxusdt'))
        WHEN 7 THEN (SELECT qts.get_price('dotusdt'))
        WHEN 8 THEN (SELECT qts.get_price('linkusdt'))
        ELSE 0
    END * quantity
    FROM qty_currency;
    RETURN qty_transaction;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ms.get_balance_portfolio(input_portfolio_id INT) 
RETURNS REAL AS $$
DECLARE
    current_balance REAL;
    tr RECORD;
BEGIN

    FOR tr IN 
        SELECT id, action_type, quantity, created_at, fk_portfolio_id, fk_currency_id
        FROM ms.transactions
        WHERE fk_portfolio_id = input_portfolio_id
        ORDER BY created_at
    LOOP
        IF tr.action_type = 'BUY' THEN
            current_balance := current_balance + ms.get_value_transaction(tr.id);
        ELSIF tr.action_type = 'SELL' THEN
            current_balance := current_balance - ms.get_value_transaction(tr.id);
        END IF;
        
        UPDATE ms.portfolios
        SET balance = current_balance
        WHERE id = input_portfolio_id;
    END LOOP;
    RETURN current_balance;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER ms.update_balance_portfolio
AFTER INSERT ON ms.transactions
FOR EACH ROW
BEGIN
    
END;