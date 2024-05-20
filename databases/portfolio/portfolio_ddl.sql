\connect postgres

DROP DATABASE IF EXISTS portfolio;
CREATE DATABASE portfolio;

\connect portfolio;

DROP SCHEMA qts CASCADE;
DROP SCHEMA ms CASCADE;
CREATE SCHEMA qts;
CREATE SCHEMA ms;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


--
-- Валидация email
--
CREATE DOMAIN ms.valid_email AS VARCHAR(255)
    CHECK (VALUE ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');


--
-- Валидация названия тикера
--
CREATE DOMAIN ms.valid_symbol AS VARCHAR(10)
    CHECK (VALUE IN (
        'btcusdt', 'ethusdt', 'solusdt', 'xrpusdt', 
        'adausdt', 'avaxusdt', 'dotusdt', 'linkusdt'
    ));


--
-- Валидация типа транзакции
--
CREATE DOMAIN ms.valid_action_type AS VARCHAR(4)
    CHECK (VALUE IN ('BUY', 'SELL'));


--
-- Валидация времени (округление до минут)
--
CREATE DOMAIN ms.valid_time AS TIMESTAMPTZ
    CHECK (date_trunc('minute', VALUE) = VALUE);


--
-- Котировки
--
CREATE TABLE qts.quotes
(
    m_symbol ms.valid_symbol NOT NULL,
    m_time TIMESTAMPTZ NOT NULL,
    m_open REAL NOT NULL,
    m_high REAL NOT NULL,
    m_low REAL NOT NULL,
    m_close REAL NOT NULL
) PARTITION BY RANGE (m_time);

CREATE TABLE qts.quotes_202404 PARTITION OF qts.quotes
FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

CREATE TABLE qts.quotes_202405 PARTITION OF qts.quotes
FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

CREATE TABLE qts.quotes_202406 PARTITION OF qts.quotes
FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

CREATE TABLE qts.quotes_202407 PARTITION OF qts.quotes
FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');


--
-- Пользователи
--
CREATE TABLE ms.users
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email ms.valid_email UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL
);


--
-- Портфели пользователей
--
CREATE TABLE ms.portfolios
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200) UNIQUE NOT NULL,
    is_published BOOLEAN DEFAULT TRUE,
    fk_user_id INT REFERENCES ms.users(id)
);


--
-- Криптовалюты
--
CREATE TABLE ms.currencies
(
    id INT PRIMARY KEY,
    symbol ms.valid_symbol DEFAULT 'btcusdt',
    description TEXT
);

INSERT INTO ms.currencies(id, symbol, description)
VALUES(1, 'btcusdt', 'Биткоин (BTC) — первая криптовалюта, созданная при участии анонима Сатоши Накамото. В своем white paper 2008 года Биткоин описывается как одноранговые (p2p) электронные деньги, которые позволяют совершать онлайн-транзакции без участия третьей стороны, какого-либо финансового института. Сеть Биткоина была запущена 3 января 2009 года с протоколом Proof-of-Work (PoW). На сегодняшний день Биткоин является самой популярной криптовалютой, с наибольшей капитализацией.'),
(2, 'ethusdt', 'Эфир, Ether (ETH) — криптовалюта блокчейн-проекта Ethereum. Он является самой популярной open-source платформой для смарт-контрактов, токенов и децентрализованных приложений (dApps). Концепция эфириума была представлена в 2013 году Виталиком Бутериным. Сеть Ethereum была запущена 30 июля 2015 года, на данный момент ее протокол базируется на Proof-of-Work, однако существует план смены протокола на Proof-of-Stake в 2020 году при запуске Ethereum 2.0.'),
(3, 'solusdt', 'Solana — это блокчейн-платформа с открытым исходным кодом, созданная в 2017 году бывшим руководителем Qualcomm, Анатолием Яковенко. Основная цель Solana — значительно повысить масштабируемость технологии блокчейна, превысив производительность популярных блокчейнов, сохранив при этом затраты на низком уровне. Это достигается за счет гибридной модели, которая позволяет сети Solana теоретически обрабатывать более 710 000 транзакций в секунду (TPS) без необходимости использования дополнительных решений по масштабированию.'),
(4, 'xrpusdt', 'XRP — криптовалюта, которая используется платежной платформой RippleNet. Та, в свою очередь, строится на технологии распределенного реестра XRP Ledger. Цель этой криптовалюты — стать быстрым, масштабируемым трансграничным средством платежа. Впервые идея платежной платформы Ripple появилась в 2004 году, в 2012 году Джед МакКалеб и Крис Ларсон взялись ее реализовать. XRP поддерживается независимыми валидаторами, которым может теоретически стать каждый желающий.'),
(5, 'adausdt', 'Cardano (ADA) — криптовалюта децентрализованной платформы, которая разрабатывается с 2015 года на языке программирования Haskell. Основателем проекта считается Чарльз Хоскинсон, который также участвовал в создании Ethereum. Cardano была запущена в результате ICO в 2017 году. Cardano поддерживается тремя независимыми друг от друга организациями: IOHK, Cardano Foundation, Emurgo. Дорожная карта развития проекта предусматривает 5 этапов, каждый из которых привносит в сеть новые функции.'),
(6, 'avaxusdt', 'Avalanche (AVAX) представляет собой блокчейн сеть, обеспечивающую надежное функционирование смарт контрактов. Сеть предназначена для децентрализованных приложений (dApps), NFT и других сложных блокчейн-платформ.'),
(7, 'dotusdt', 'Polkadot — это протокол, который позволяет передавать любые типы данных или активов между блокчейнами. Объединяя несколько блокчейнов, Polkadot стремится достичь высокой степени безопасности и масштабируемости. DOT — это токен управления протоколом. Его можно использовать для стейкинга, чтобы защищать сеть или подключать («связывать») новые цепочки.'),
(8, 'linkusdt', 'Chainlink (LINK) — сеть-«оракул», предназначенная для объединения смарт-контрактов с реальными данными. Была основана в результате ICO в сентябре 2017 года Сергеем Назаровым и Стивом Эллисом. LINK является токеном стандарта ERC20 с функционалом ERC223. Оракулы — объекты вне сети блокчейна, которые поставляют информацию для смарт-контрактов.');



--
-- Транзакции (покупка/продажа тикера в портфеле)
--
CREATE TABLE ms.transactions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type ms.valid_action_type DEFAULT 'BUY',
    quantity REAL NOT NULL,
    created_at ms.valid_time DEFAULT date_trunc('minute', NOW()),
    fk_portfolio_id INT REFERENCES ms.portfolios(id),
    fk_currency_id INT REFERENCES ms.currencies(id)
);