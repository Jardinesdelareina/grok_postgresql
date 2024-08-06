CREATE OR REPLACE FUNCTION trading.scalping_classic(portfolio_id INT) 
RETURNS VOID AS $$
DECLARE
    title_bot VARCHAR(100) := 'scalping_classic';
    symbol VARCHAR(20) := 'xrpusdt';
    quantity NUMERIC := 1000;
    last_price NUMERIC;
    min_price_range NUMERIC;
    max_price_range NUMERIC;
    open_position BOOLEAN := FALSE;
BEGIN
    last_price := (SELECT market.get_price(symbol));
    MIN_price_range := (SELECT MIN(t_price) 
                    FROM market.tickers 
                    WHERE fk_symbol = symbol AND t_time BETWEEN NOW() - INTERVAL '1 hour' AND NOW());
    max_price_range := (SELECT MAX(t_price) 
                    FROM market.tickers 
                    WHERE fk_symbol = symbol AND t_time BETWEEN NOW() - INTERVAL '1 hour' AND NOW());

    WHILE TRUE
    LOOP
        IF NOT open_position THEN
            IF last_price > (min_price_range + (min_price_range * 0.01)) THEN
                open_position := TRUE;
                CALL trading.create_transaction('BUY', quantity, portfolio_id, symbol);
            ELSE
                RAISE NOTICE 'Ожидание BUY';
            END IF;
        END IF;
        IF open_position THEN
            IF last_price < (max_price_range + (max_price_range * 0.01)) THEN
                open_position := false;
                CALL trading.create_transaction('SELL', quantity, portfolio_id, symbol);
            ELSE
                RAISE NOTICE 'Ожидание SELL';
            END IF;
        END IF;
    END loop;
END;
$$ language plpgsql;
COMMENT ON FUNCTION trading.scalping_classic(INT) IS 'Торговая стратегия классического стальпинга';


DO $$
DECLARE
    build_random_string VARCHAR(8) := LEFT((MD5(RANDOM()::TEXT)), 8);
    build_user TEXT := 'user_' || build_random_string || '@gmail.com';
    build_portfolio TEXT := 'portfolio_' || build_random_string;
BEGIN
    CALL profile.create_user(
        build_user, 
        build_random_string
    );
    COMMIT;
    CALL profile.create_portfolio(
        build_portfolio,
        build_user
    );
    COMMIT;
    RAISE NOTICE 'Пользователь % Портфель % добавлен', build_user, build_portfolio;
    SELECT trading.scalping_classic(1);
END $$;