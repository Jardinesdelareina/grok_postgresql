-- Получение последней цены закрытия определенного тикера
CREATE OR REPLACE FUNCTION qts.get_price(input_symbol VARCHAR(10)) 
RETURNS REAL AS $$
    SELECT m_close AS last_price 
    FROM qts.quotes 
    WHERE m_symbol = input_symbol
    ORDER BY m_time DESC 
    LIMIT 1;
$$ LANGUAGE sql VOLATILE;


-- Вывод списка портфелей определенного пользователя
CREATE OR REPLACE FUNCTION ms.get_portfolios(input_user_id INT) 
RETURNS SETOF ms.portfolios AS $$
BEGIN

    RETURN QUERY SELECT id, title, balance, is_published, fk_user_id
                FROM ms.portfolios 
                WHERE fk_user_id = input_user_id;

END;
$$ LANGUAGE plpgsql VOLATILE;


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
$$ LANGUAGE plpgsql VOLATILE;


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
$$ LANGUAGE plpgsql VOLATILE;


-- Вывод баланса портфеля в usdt
CREATE OR REPLACE FUNCTION ms.get_balance_portfolio(input_portfolio_id INT)
RETURNS REAL AS $$
DECLARE
    total_quantity REAL := 0;
BEGIN
    SELECT SUM(CASE WHEN t.action_type = 'BUY' THEN t.quantity 
                    ELSE -t.quantity 
                    END) * ms.get_value_transaction(t.id) 
    INTO total_quantity
    FROM ms.transactions t
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY id;

    RETURN total_quantity;
END;
$$ LANGUAGE plpgsql VOLATILE;


-- Вывод криптовалют, их количества и балансов в портфеле
CREATE OR REPLACE FUNCTION ms.get_balance_ticker_portfolio(input_portfolio_id INT) 
RETURNS SETOF ms.transactions AS $$
BEGIN

    SELECT DISTINCT fk_currency_id, SUM(CASE WHEN t.action_type = 'BUY' THEN t.quantity 
                                            ELSE -t.quantity END) AS qty_currency
    FROM ms.transactions t
    JOIN ms.currencies c ON t.id
	GROUP BY id;
    
    RETURN total_quantity;
$$ LANGUAGE plpgsql VOLATILE;


-- Вывод криптовалют и их балансов в портфеле
CREATE OR REPLACE FUNCTION ms.get_total_balance_user(input_user_id INT) 
RETURNS REAL AS $$

$$ LANGUAGE plpgsql VOLATILE;