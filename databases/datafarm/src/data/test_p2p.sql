/* 
Тестирование работы жизненного цикла заключения сделки p2p: 
1. Создание двух пользователей,
2. Создание у обоих пользоваелей кошельков BTC,
3. Наполнение кошельков тестовыми 100 BTC,
4. Выставления предложения на продажу: предложение выставляется если у создателя предложения
    баланс кошелька больше размера его заявки в предложении,
5. Открытие сделки на предложение другим пользователем,
6. Проверка времени жизни сделки,
7. Перечисление средств с кошелька на кошелек.
*/
DO $$
DECLARE
    build_random_string VARCHAR(8) := LEFT((MD5(RANDOM()::TEXT)), 8);
    build_user TEXT;
    target_exchange_currency VARCHAR(6) := 'BTC';
    offer_qty NUMERIC := 5;
    offer_min NUMERIC := 1;
    offer_max NUMERIC := NULL;
    offer_creator TEXT;
    deal_contragent TEXT;
    last_offer BIGINT;
    last_deal UUID;
    deal_qty NUMERIC := 50;
BEGIN
    FOR i IN 1..2 LOOP
        build_user := 'user_' || build_random_string || i || '@mail.com';
        CALL profile.create_user(build_user, '1234');
        CALL p2p.create_wallet(build_user, target_exchange_currency);
        
        UPDATE p2p.wallets 
        SET balance = 100 
        WHERE fk_user_owner = build_user AND fk_currency = target_exchange_currency;
    END LOOP;
    COMMIT;
    
    IF (
        SELECT w.balance AS balance
        FROM profile.users u
        JOIN p2p.wallets w ON u.email = w.fk_user_owner
        LIMIT 1
        ) >= offer_qty THEN
        offer_creator := (
            SELECT email FROM (
                SELECT u.email AS email
                FROM profile.users u
                JOIN p2p.wallets w ON u.email = w.fk_user_owner
                ORDER BY email
                LIMIT 1
            ) AS subquery
        );
        CALL p2p.create_offer(
            'SELL', 
            target_exchange_currency, 
            offer_qty,
            offer_min,
            offer_max, 
            'Comment', 
            offer_creator
        );
    ELSE 
        RAISE NOTICE 'Баланс пользователя % недостаточен для выставления предложения', offer_creator;
    END IF;
    COMMIT;

    deal_contragent := (
        SELECT email FROM (
            SELECT u.email AS email
            FROM profile.users u
            JOIN p2p.wallets w ON u.email = w.fk_user_owner
            ORDER BY email
            LIMIT 1 OFFSET 1
        ) AS subquery
    );
    CALL p2p.create_deal(4, 1, deal_contragent);
    COMMIT;

    PERFORM pg_sleep(5);

    last_offer := (SELECT id FROM p2p.offers LIMIT 1);
    last_deal := (SELECT id FROM p2p.deals LIMIT 1);
    CALL p2p.check_deal_time(last_deal);
    COMMIT;

    CALL p2p.deal_payment(last_offer, last_deal);
    CALL p2p.create_p2p_transaction(
        offer_creator, 
        deal_contragent, 
        target_exchange_currency, 
        deal_qty
    );
    COMMIT;
END $$;

/* 
Скрипт должен вернуть при запросе SELECT * FROM p2p.wallets двух пользователей, 
баланс которых у одного 50, у другого 150.

Запрос SELECT * FROM p2p.offers должен вернуть активное предложение с уменьшенным на размер 
сделки quantity,

Запрос SELECT * FROM p2p.deals должен вернуть сделку со статусом PAYED.
*/