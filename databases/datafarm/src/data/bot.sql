DO $$
DECLARE
    title_bot VARCHAR(100) := 'scalping_classic';
    test_user_email TEXT := 'fueros@mail.ru';
    test_portfolio_title VARCHAR(128) := 'Классический скальпинг';
    symbol VARCHAR(20) := 'xrpusdt';
    portfolio_id INT := '1';
    quantity NUMERIC := 1000;
    last_price NUMERIC;
    min_price_range NUMERIC;
    max_price_range NUMERIC;
    open_position BOOLEAN := FALSE;
BEGIN
    CALL profile.create_user(test_user_email, '1234');
    CALL profile.create_portfolio('Классический скальпинг', test_user_email);
    RAISE NOTICE 'Пользователь % Портфель % добавлен', test_user_email, test_portfolio_title;
    COMMIT;

    last_price := (SELECT market.get_price(symbol));
    min_price_range := (SELECT MIN(t_price) 
                    FROM market.tickers 
                    WHERE fk_symbol = symbol AND t_time BETWEEN NOW() - INTERVAL '1 hour' AND NOW());
    max_price_range := (SELECT MAX(t_price) 
                    FROM market.tickers 
                    WHERE fk_symbol = symbol AND t_time BETWEEN NOW() - INTERVAL '1 hour' AND NOW());

    WHILE TRUE
    LOOP
        IF NOT open_position THEN
            IF last_price > (min_price_range + (min_price_range * 0.01)) THEN
                CALL trading.create_transaction('BUY', quantity, portfolio_id, symbol);
                open_position := TRUE;
            ELSE
                RAISE NOTICE 'Ожидание BUY';
            END IF;
        END IF;
        IF open_position THEN
            IF last_price < (max_price_range + (max_price_range * 0.01)) THEN
                CALL trading.create_transaction('SELL', quantity, portfolio_id, symbol);
                open_position := FALSE;
            ELSE
                RAISE NOTICE 'Ожидание SELL';
            END IF;
        END IF;
    END LOOP;
$$ END;