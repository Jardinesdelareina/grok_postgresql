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


-- Изменение баланса портфеля в зависимости от параметров транзакции
CREATE OR REPLACE FUNCTION ms.update_balance() RETURNS trigger AS $$
DECLARE
    transaction_quantity REAL;
BEGIN
    transaction_quantity := qts.get_value_transaction(NEW.ms.transactions.id);
    IF NEW.ms.portfolios.balance IS NOT NULL AND OLD.ms.portfolios.balance IS NOT NULL THEN
        IF NEW.ms.transactions.action_type = 'BUY' THEN
            UPDATE ms.portfolios
            SET balance = balance + (NEW.quantity * transaction_quantity)
            WHERE id = NEW.ms.transactions.fk_portfolio_id;
        ELSIF NEW.ms.transactions.action_type = 'SELL' THEN
            IF ms.portfolios.balance > 0 THEN
                UPDATE ms.portfolios
                SET balance = balance - (NEW.quantity * transaction_quantity)
                WHERE id = NEW.ms.transactions.fk_portfolio_id;
            ELSE
                RAISE EXCEPTION 'Баланс не может быть отрицательным';
            END IF;
        END IF;
    ELSE
        RAISE EXCEPTION 'Баланс не может быть NULL';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_balance_trigger
AFTER UPDATE ON ms.portfolios
FOR EACH ROW EXECUTE FUNCTION ms.update_balance();