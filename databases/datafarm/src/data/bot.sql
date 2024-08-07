DO $$
DECLARE
    build_random_string VARCHAR(8) := LEFT((MD5(RANDOM()::TEXT)), 8);
    build_user TEXT := 'user_' || build_random_string || '@gmail.com';
    build_portfolio TEXT := 'portfolio_' || build_random_string;
    portfolio_id INT := (SELECT id FROM profile.portfolios WHERE title = build_portfolio);
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
    SELECT trading.scalping_classic(portfolio_id);
END $$;