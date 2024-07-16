DROP FUNCTION IF EXISTS trading.generate_num;
CREATE OR REPLACE FUNCTION trading.generate_num(limit_num BIGINT) RETURNS INT AS $$
    SELECT floor(random() * limit_num) + 1;
$$ LANGUAGE sql;


TRUNCATE TABLE trading.transactions CASCADE;
TRUNCATE TABLE profile.portfolios CASCADE;
TRUNCATE TABLE profile.users CASCADE;


/* CALL profile.create_user('fueros.dev@mail.ru', '1234');
CALL profile.create_user('developer@gmail.ru', '123456'); */

/* CALL profile.create_portfolio('portfolio1btc', 1);
CALL profile.create_portfolio('cryptoportfolio', 1);
CALL profile.create_portfolio('testnameportfolio', 2); */

CALL trading.create_bot('scalping', '---', '{"symbol": "btcusdt"}');
CALL trading.create_bot('grid', '---', '{"symbol": "btcusdt"}');

/* CALL trading.create_transaction('BUY', 1.22, 1, 1, 1);
CALL trading.create_transaction('BUY', 0.44, 1, 1, 1);
CALL trading.create_transaction('SELL', 0.874, 1, 1, 1);
CALL trading.create_transaction('BUY', 33, 2, 2, 1);
CALL trading.create_transaction('BUY', 3343, 2, 5, 2);
CALL trading.create_transaction('BUY', 3343, 3, 4, 2); */


-- Запускать только при работающем потоке котировок
-- Иначе не будет актуальных данных о времени транзакции (на текущее время не будет текущей котировки)
DO $$
BEGIN
    FOR i IN 1..1000 LOOP
        CALL profile.create_user(
            'user_' || i || '@gmail.com', 
            profile.crypt(LEFT((md5(random()::text)), 8), profile.gen_salt('md5'))
        );
    END LOOP;
END $$;


DO $$
BEGIN
    FOR i IN 1..10000 LOOP
        CALL profile.create_portfolio(
            'portfolio_' || i,
            'user_' || trading.generate_num(900) || '@gmail.com'
        );
    END LOOP;
END $$;


DO $$
BEGIN
    FOR i IN 1..50000 LOOP
        CALL trading.create_transaction(
            CASE WHEN random() < 0.1 THEN 'SELL' ELSE 'BUY' END,
            trading.generate_num(3),
            trading.generate_num(9000),
            'btcusdt',
            trading.generate_num(2)
        );
    END LOOP;
END $$;