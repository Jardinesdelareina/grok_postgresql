DROP FUNCTION IF EXISTS ms.generate_num;
CREATE OR REPLACE FUNCTION ms.generate_num(limit_num BIGINT) RETURNS INT AS $$
    SELECT floor(random() * limit_num) + 1;
$$ LANGUAGE sql;



CALL ms.create_user('fueros.dev@mail.ru', '1234');
CALL ms.create_user('emirdegranada@gmail.ru', '123456');

CALL ms.create_portfolio('portfolio1btc', TRUE, 1);
CALL ms.create_portfolio('cryptoportfolio', TRUE, 1);
CALL ms.create_portfolio('testnameportfolio', TRUE, 2);

CALL ms.create_transaction('BUY', 1.22, 1, 1);
CALL ms.create_transaction('BUY', 0.44, 1, 1);
CALL ms.create_transaction('SELL', 0.874, 1, 1);
CALL ms.create_transaction('BUY', 33, 2, 2);
CALL ms.create_transaction('BUY', 3343, 2, 5);
CALL ms.create_transaction('BUY', 3343, 3, 4);

-- Запускать только при работающем потоке котировок
-- Иначе не будет актуальных данных о времени транзакции (на текущее время не будет текущей котировки)
DO $$
BEGIN
    FOR i IN 1..50000 LOOP
        INSERT INTO ms.transactions(action_type, quantity, fk_portfolio_id, fk_currency_id)
        VALUES (
            CASE WHEN random() < 0.1 THEN 'SELL' ELSE 'BUY' END,
            ms.generate_num(3),
            1,
            1
        );
    END LOOP;
END $$;