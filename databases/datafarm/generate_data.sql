-- Генерация тестовых данных
DO $$
DECLARE
    count_users INT := 100000;
    count_portfolios SMALLINT := 10;
    count_transactions INT := service.generate_num(50000);
    build_random_string VARCHAR(8) := LEFT((md5(random()::text)), 8);
    build_user VARCHAR;
    random_symbol VARCHAR(20);
    random_quantity NUMERIC;
    random_portfolio_id INT;
BEGIN
    -- Создание пользователя
    FOR i IN 1..count_users LOOP
        build_user := 'user_' || build_random_string || i || '@gmail.com';
        CALL profile.create_user(
            build_user, 
            profile.crypt(build_random_string, profile.gen_salt('md5'))
        );
        COMMIT;
        RAISE NOTICE 'Пользователь % добавлен', i;
        PERFORM PG_SLEEP(1);

        -- Создание портфеля
        FOR j IN 1..service.generate_num(count_portfolios) LOOP
            CALL profile.create_portfolio(
                'portfolio_' || LEFT((md5(random()::text)), 8) || j || '_user_' || i,
                build_user
            );
            COMMIT;
            RAISE NOTICE 'Пользователь % Портфель % добавлен', i, j;
            PERFORM PG_SLEEP(1);

            -- Создание транзакции
            FOR l IN 1..count_transactions LOOP
                BEGIN
                    SELECT symbol INTO random_symbol FROM market.currencies ORDER BY random() LIMIT 1;
                    SELECT service.count_after_comma(market.get_price(random_symbol))::NUMERIC INTO random_quantity;
                    SELECT id INTO random_portfolio_id FROM profile.portfolios ORDER BY random() LIMIT 1;
                    CALL trading.create_transaction(
                        CASE WHEN service.generate_num(5) > 1 THEN 'BUY' ELSE 'SELL' END,
                        random_quantity,
                        random_portfolio_id,
                        random_symbol
                    );
                    COMMIT;
                    RAISE NOTICE 'Пользователь % Портфель % Транзакция % добавлена', i, j, l;
                    PERFORM PG_SLEEP(1);
                END;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;