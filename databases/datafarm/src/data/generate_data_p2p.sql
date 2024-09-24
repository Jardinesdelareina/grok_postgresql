-- Генерация тестовых данных p2p
DO $$
DECLARE
    count_users INT := 100;
    build_random_string VARCHAR(8) := LEFT((MD5(RANDOM()::TEXT)), 8);
    build_user TEXT;
    random_ticker VARCHAR(6);
    random_ticker_offer VARCHAR(6);
    random_quantity_offer NUMERIC;
    comment TEXT;
    email_creator_offer TEXT;
BEGIN
    -- Создание пользователей и счетов, наполнение счетов
    FOR i IN 1..count_users LOOP
        build_user := 'user_' || build_random_string || i || '@mail.com';
        CALL profile.create_user(
            build_user, 
            build_random_string
        );
        COMMIT;
        RAISE NOTICE 'Пользователь % добавлен', i;

        random_ticker := (SELECT ticker 
                        FROM p2p.exchange_currencies 
                        ORDER BY RANDOM() 
                        LIMIT 1);
        CALL p2p.create_wallet(build_user, random_ticker);
        COMMIT;
        RAISE NOTICE 'Счет % у пользователя % создан', random_ticker, i;

        UPDATE p2p.wallets 
        SET balance = 100 
        WHERE fk_user_owner = build_user AND fk_currency = random_ticker;
        RAISE NOTICE 'Баланс счета % у пользователя % изменен', random_ticker, i;
        COMMIT;
    END LOOP;

    -- Процесс создания предложений и сделок
    WHILE TRUE
    LOOP
        random_ticker_offer := (SELECT ticker FROM p2p.exchange_currencies ORDER BY RANDOM() LIMIT 1);
        random_quantity_offer := (SELECT service.generate_num(100));
        email_creator_offer := (SELECT email FROM profile.users ORDER BY RANDOM() LIMIT 1);
        comment := (SELECT title FROM p2p.emitents ORDER BY RANDOM() LIMIT 1);
        IF (SELECT service.generate_num(5) > 2) THEN
            CALL p2p.create_offer(
                'BUY', 
                random_ticker_offer,
                random_quantity_offer,
                ROUND((random_quantity_offer / 100) * 5),
                NULL,
                'Платежный способ: ' || comment,
                email_creator_offer
            );
            COMMIT;
            PERFORM PG_SLEEP(1);
        ELSE
            CALL p2p.create_offer(
                'SELL', 
                random_ticker_offer,
                random_quantity_offer,
                ROUND((random_quantity_offer / 100) * 5),
                NULL,
                'Платежный способ: ' || comment,
                email_creator_offer
            );
        END IF;
        RAISE NOTICE 'Оффер';
    END LOOP;
END $$;