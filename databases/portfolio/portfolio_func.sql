-- Назначение id определенному тикеру
CREATE OR REPLACE FUNCTION ms.symbol_id(input_symbol_id INT) 
RETURNS ms.valid_symbol AS $$
DECLARE
    symbol_id INT := input_symbol_id;
    symbol VARCHAR(10);
BEGIN
    IF symbol_id = 1 THEN symbol := 'btcusdt';
    ELSIF symbol_id = 2 THEN symbol := 'ethusdt';
    ELSIF symbol_id = 3 THEN symbol := 'solusdt';
    ELSIF symbol_id = 4 THEN symbol := 'xrpusdt';
    ELSIF symbol_id = 5 THEN symbol := 'adausdt';
    ELSIF symbol_id = 6 THEN symbol := 'avaxusdt';
    ELSIF symbol_id = 7 THEN symbol := 'dotusdt';
    ELSIF symbol_id = 8 THEN symbol := 'linkusdt';
    ELSE RAISE WARNING 'Несуществующий тикер';
    END IF;
    RETURN symbol;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Получение последней цены закрытия определенного тикера
CREATE OR REPLACE FUNCTION qts.get_price(input_symbol ms.valid_symbol) 
RETURNS REAL AS $$
    SELECT m_close AS last_price 
    FROM qts.quotes 
    WHERE m_symbol = input_symbol
    ORDER BY m_time DESC 
    LIMIT 1;
$$ LANGUAGE sql VOLATILE;


-- Получение нужной котировки по выбранному тикеру в выбранный момент времени
CREATE OR REPLACE FUNCTION qts.get_price_with_time(
    input_symbol ms.valid_symbol,
    input_time TIMESTAMPTZ
) RETURNS REAL AS $$
    SELECT m_close AS current_price
    FROM qts.quotes
    WHERE m_symbol = input_symbol AND m_time = input_time
$$ LANGUAGE sql IMMUTABLE;


-- Вывод списка портфелей определенного пользователя
CREATE OR REPLACE FUNCTION ms.get_portfolios(input_user_id INT) 
RETURNS TABLE(title VARCHAR(200), is_published BOOLEAN) AS $$
BEGIN
    RETURN QUERY SELECT p.title, p.is_published
                FROM ms.portfolios p
                WHERE fk_user_id = input_user_id;
END;
$$ LANGUAGE plpgsql STABLE;


-- Расчет объема транзакции в usdt
CREATE OR REPLACE FUNCTION ms.get_value_transaction(input_transaction_id UUID) 
RETURNS REAL AS $$
DECLARE qty_transaction REAL;
BEGIN
    WITH qty_currency AS (
        SELECT t.created_at, t.quantity, t.fk_currency_id AS curr
        FROM ms.transactions t
        WHERE t.id = input_transaction_id
    )
    SELECT quantity * qts.get_price_with_time(ms.symbol_id(curr), created_at)
	INTO qty_transaction
    FROM qty_currency;
    RETURN qty_transaction;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Вывод баланса портфеля в usdt
CREATE OR REPLACE FUNCTION ms.get_balance_portfolio(input_portfolio_id INT)
RETURNS REAL AS $$
DECLARE total_quantity REAL := 0;
BEGIN
    SELECT SUM(
        CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
    ) * qts.get_price(ms.symbol_id(t.fk_currency_id))
    INTO total_quantity
    FROM ms.transactions t
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY fk_currency_id, t.created_at;
    IF total_quantity < 0 THEN 
        total_quantity = 0;
	END IF;
    RETURN total_quantity;
END;
$$ LANGUAGE plpgsql VOLATILE;


-- Вывод криптовалют, их количества и балансов в портфеле
CREATE OR REPLACE FUNCTION ms.get_balance_ticker_portfolio(input_portfolio_id INT) 
RETURNS TABLE(symbol ms.valid_symbol, qty_currency REAL, usdt_qty_currency REAL) AS $$
BEGIN
    RETURN QUERY SELECT DISTINCT 
        ms.symbol_id(fk_currency_id) AS symbol, 
        SUM(
            CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
        ) AS qty_currency, 
        SUM(
            CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
        ) * qts.get_price(ms.symbol_id(fk_currency_id)) AS usdt_qty_currency
    FROM ms.transactions t
    JOIN ms.currencies c ON t.fk_currency_id = c.id
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY fk_currency_id;
END;
$$ LANGUAGE plpgsql VOLATILE;


-- Вывод совокупного баланса пользователя
CREATE OR REPLACE FUNCTION ms.get_total_balance_user(input_user_id INT) 
RETURNS REAL AS $$
DECLARE total_balance REAL := 0;
        portfolio_id INT;
BEGIN
    FOR portfolio_id IN (
        SELECT id 
        FROM ms.portfolios 
        WHERE fk_user_id = input_user_id
    ) 
    LOOP
        total_balance := total_balance + ms.get_balance_portfolio(portfolio_id);
    END LOOP;
    RETURN total_balance;
END;
$$ LANGUAGE plpgsql VOLATILE;