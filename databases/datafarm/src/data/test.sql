call profile.create_user('fueros@mail.ru', '1234');
call profile.create_user('mueros@mail.ru', '1234');
call p2p.create_offer('BUY', 'btc', 100, 'comment', 'fueros@mail.ru');
call p2p.create_deal(76, 1, 'mueros@mail.ru');
--call p2p.create_deal(23, 1, 'mueros@mail.ru');
--call p2p.create_deal(134, 1, 'mueros@mail.ru');
--call p2p.deal_payment(1, '48f6e0b2-0502-4d39-8002-c896074bae88');