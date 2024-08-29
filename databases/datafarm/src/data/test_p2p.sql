CALL profile.create_user('fueros@mail.ru', '1234');
CALL profile.create_user('mueros@mail.ru', '1234');
CALL p2p.create_offer('BUY', 'btc', 5, NULL, NULL, 'Comment', 'fueros@mail.ru');
--CALL p2p.create_deal(4, 1, 'mueros@mail.ru');
--CALL p2p.create_deal(1, 1, 'mueros@mail.ru');