call profile.create_user('fueros@mail.ru', '1234');
call profile.create_user('mueros@mail.ru', '1234');
call p2p.create_offer('SELL', 'btc', 5, 2, 'comment', 'fueros@mail.ru');
call p2p.create_review('positive', 'comment positive', 'fueros@mail.ru', 'mueros@mail.ru');
call p2p.create_deal(80, 1, 'mueros@mail.ru', 'fueros@mail.ru');