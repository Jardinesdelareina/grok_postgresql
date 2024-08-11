DO $$
DECLARE
    title_bot VARCHAR(100) := 'scalping_classic';
    test_user_email TEXT := 'fueros@mail.ru';
    test_portfolio_title VARCHAR(128) := 'Классический скальпинг';
    portfolio_id INT := 1;
    quantity NUMERIC := 1000;
    last_price NUMERIC;
    min_price_range NUMERIC;
    max_price_range NUMERIC;
    quarter_time_range NUMERIC;
    min_interval NUMERIC := 0.002;
    open_position BOOLEAN := FALSE;
    symbol_list VARCHAR[] := ARRAY[
        'btcusdt', 'ethusdt', 'solusdt', 'xrpusdt'
    ];
    i VARCHAR;
BEGIN
    CALL profile.create_user(test_user_email, '1234');
    CALL profile.create_portfolio('Классический скальпинг', test_user_email);
    RAISE NOTICE 'Пользователь % Портфель % добавлен', test_user_email, test_portfolio_title;
    COMMIT;

    WHILE TRUE
    LOOP
        FOREACH i IN ARRAY symbol_list
        LOOP
            min_price_range := (SELECT MIN(t_price) 
                                FROM market.tickers 
                                WHERE fk_symbol = i 
                                AND t_time BETWEEN NOW() - INTERVAL '1 hour' AND NOW());
            max_price_range := (SELECT MAX(t_price) 
                                FROM market.tickers 
                                WHERE fk_symbol = i 
                                AND t_time BETWEEN NOW() - INTERVAL '1 hour' AND NOW());
            last_price := (SELECT market.get_price(i));
            quarter_time_range := ABS(((max_price_range - min_price_range) * 0.25) / last_price);
            IF NOT open_position THEN
                IF last_price > (min_price_range + (min_price_range * quarter_time_range)) THEN
                    CALL trading.create_transaction('BUY', quantity, portfolio_id, i);
                    CALL service.drop_tickers(i);
                    open_position := TRUE;
                    RAISE NOTICE '[BUY] % : %', i, quantity;
                ELSE
                    RAISE NOTICE '[AWAIT] BUY %', i;
                END IF;
            END IF;
            IF open_position THEN
                IF last_price < (max_price_range + (max_price_range * quarter_time_range)) THEN
                    CALL trading.create_transaction('SELL', quantity, portfolio_id, i);
                    CALL service.drop_tickers(i);
                    open_position := FALSE;
                    RAISE NOTICE '[SELL] % : %', i, quantity;
                ELSE
                    RAISE NOTICE '[AWAIT] BUY %', i;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END $$;