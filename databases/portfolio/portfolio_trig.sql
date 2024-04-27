-- Изменение баланса портфеля в зависимости от параметров транзакции
CREATE OR REPLACE FUNCTION ms.alert_new_transaction() RETURNS trigger AS $$
BEGIN
    RAISE NOTICE 'Добавлена новая транзакция';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER alert_new_transaction_trigger
AFTER INSERT ON ms.transactions
FOR EACH ROW EXECUTE FUNCTION ms.alert_new_transaction();