-- Получение последней цены закрытия определенного тикера
CREATE OR REPLACE FUNCTION qts.get_price(input_symbol VARCHAR(10)) RETURNS REAL AS $$
    SELECT m_close AS last_price 
    FROM qts.quotes 
    WHERE m_symbol = input_symbol
    ORDER BY m_time DESC 
    LIMIT 1;
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