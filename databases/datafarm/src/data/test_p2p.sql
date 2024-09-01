CALL profile.create_user('fueros@mail.ru', '1234');
CALL profile.create_user('mueros@mail.ru', '1234');
CALL p2p.create_offer('BUY', 'btc', 5, 3, NULL, 'Comment', 'fueros@mail.ru');
CALL p2p.create_deal(4, 1, 'mueros@mail.ru');
CALL p2p.create_deal(1, 1, 'mueros@mail.ru');
--CALL p2p.check_deal_time('7100bacd-20a2-462b-9c4d-86ac8558e6df');
--CALL p2p.deal_payment(1, 'cc23797a-12ea-4d68-90d8-e0b34f687a5f');