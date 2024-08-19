call profile.create_user('fueros@mail.ru', '1234');
call profile.create_user('mueros@mail.ru', '1234');
call p2p.create_offer('BUY', 'btc', 50, 2, 40, 'comment', 'fueros@mail.ru');
call p2p.create_deal(46, 1, 'mueros@mail.ru');
--call p2p.deal_payment(1, 'ebf4747a-0a2a-4785-ba85-a4feb13e3954');