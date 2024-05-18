# Документация к базе данных Portfolio

Portfolio - это сервис для составления криптовалютных портфелей. Как происходит процесс формирования портфеля: сначала зарегистрированный в системе пользователь создает портфель, определив его название и область видимости (публичный / не публичный). Далее происходит создание транзакций - пользователь изменяет баланс своего портфеля торговыми операциями операциями BUY или SELL. Таким образом если определенного актива на балансе пользователя больше 0, то его стоимость будет изменяться в зависимости от цены актива на бирже. 

У пользователя может быть несколько портфелей. Можно следить как за балансом отдельного портфеля, так и за совокупным балансом всех портфелей пользователя. Также есть функционал отслеживания актуальных цен криптовалютных тикеров.


### Схема 'qts'

#### Таблица 'quotes'

Таблица представляет собой хранилице исторических данных о ценовых изменениях криптовалют. Данные загружаются порциями - каждую минуту по каждому тикеру. Таблица партиционируется помесячно.

|FK|PK|Column|Type|Length|Unique|Nullable|Description|
|---|---|---|---|---|---|---|---|
|||m_symbol|varchar|10||*|Название тикера|
|||m_time|timestamptz|||*|Время записи|
|||m_open|real|||*|Цена открытия|
|||m_high|real|||*|Наибольшая цена за период|
|||m_low|real|||*|Наименьшая цена за период|
|||m_close|real|||*|Цена закрытия|

Функционал:

|Title|Type|Params|Description|
|---|---|---|---|
|get_price|Функция|input_symbol VARCHAR(10) - криптовалютный тикер, по которому будет браться цена|Получение последней цены закрытия определенного тикера|


### Схема 'ms'

#### Домены 

|Title|Type|Params|Description|
|---|---|---|---|
|valid_email|Type|VARCHAR(255)|Валидация email|
|valid_symbol|Type|VARCHAR(10)|Валидация тикеров, ограничение списка тикеров|
|valid_action_type|VARCHAR(4)|Params|Валидация названия действия, ограничение списка действий|
|valid_time|TIMESTAMPTZ|Params|Валидация времени, округление до минут|


#### Таблица 'users'

Таблица пользователей сервиса. Она хранит авторизационные данные и связана с таблицей `portfolios` связью one-to-many (пользователь может иметь несколько портфелей).

|FK|PK|Column|Type|Length|Unique|Nullable|Description|
|---|---|---|---|---|---|---|---|
||*|id|int||*|*|Идентификатор записи|
|||email|valid_email||*|*|Адрес электронной почты пользователя|
|||password|varchar|100||*|Зашифрованный пароль пользователя|


#### Таблица 'portfolios'

Таблица портфелей пользователей. В ней хранятся данные о параметрах создаваемых пользователями портфелях, а также внешний ключ, связывающий `portfolios` с `users` через primary key. Помимо этого есть связь one-to-many с таблицей `transactions` (несколько транзакций могут быть в рамках одного портфеля).

|FK|PK|Column|Type|Length|Unique|Nullable|Description|
|---|---|---|---|---|---|---|---|
||*|id|int||*|*|Идентификатор записи|
|||title|varchar|200|*|*|Название портфеля|
||is_published|bool||||*|Публичный / не публичный, по-умолчанию публичный|
|users(id)||fk_user_id|int|||*|Идентификатор пользователя, кому принадлежит портфель|

Индексы:

|Title|Columns|
|---|---|
|idx_portfolios_user|fk_user_id|


#### Таблица 'currencies'

Информационная таблица о криптовалютах. Хранит название тикера и описание проекта, за ним стоящего. Имеет связь one-to-one с таблицей `transactions` (одна транзакция может совершаться только по одной криптовалюте).

|FK|PK|Column|Type|Length|Unique|Nullable|Description|
|---|---|---|---|---|---|---|---|
||*|id|int||*|*|Идентификатор записи|
|||symbol|valid_symbol|||*|Тикер криптовалюты|
|||description|text||||Описание криптовалюты|


#### Таблица 'transactions'

Таблица транзакций, совершаемых пользователями в рамках своих портфелей. Содержит внешние ключи, связывающие `transactions` с таблицами `portfolios` и `currencies` по primary key. Является ключевой таблицей проекта, так как содержит данные, по которым расчитываются балансы портфелей.

|FK|PK|Column|Type|Length|Unique|Nullable|Description|
|---|---|---|---|---|---|---|---|
||*|id|bigint||*|*|Идентификатор записи|
|||action_type|valid_action_type|||*|Тип транзакции, по-умолчанию BUY|
|||quantity|real|||*|Количество криптовалюты в транзакции|
|||created_at|valid_time|||*|Время создания транзакции, по-умолчанию текущее время|
|portfolios(id)||fk_portfolio_id|int|||*|Идентификатор портфеля, в рамках которого происходит транзакция|
|currencies(id)||fk_currency_id|int|||*|Идентификатор криптовалюты, с которой происходит транзакция|

Индексы:

|Title|Columns|
|---|---|
|idx_transactions_portfolio|fk_portfolio_id|
|idx_transactions_currency|fk_currency_id|


### Функционал

|Title|Type|Params|Description|
|---|---|---|---|
|create_user|Процедура|input_email VARCHAR(255) - ввод email, input_password VARCHAR(100) - ввод пароля|Создание пользователя, ввод регистрационных данных|
|create_portfolio|Процедура|input_title VARCHAR(200) - ввод названия портфеля, input_is_published BOOLEAN - установка публичности, input_user_id INT - ввод идентификатора пользователя, которому принадлежит портфель|Создание криптовалютного портфеля|
|get_portfolios|Функция|input_user_id INT - идентификатор пользователя|Вывод списка портфелей определенного пользователя|
|update_portfolio|Процедура|input_portfolio_id INT - идентификатор портфеля, input_portfolio_title VARCHAR(200) - новое значение title, input_portfolio_is_published BOOLEAN - новое значение is_published|Изменение параметров портфеля|
|get_balance_portfolio|Функция|input_portfolio_id INT - идентификатор портфолио|Вывод баланса портфеля в usdt|
|create_transaction|Процедура|input_action_type VARCHAR(4) - ввод типа транзакции, input_quantity REAL - ввод количества криптовалюты, input_portfolio_id INT - ввод идентификатора портфеля, input_currency_id INT - ввод индентификатора криптовалюты|Создание транзакции|
|get_value_transaction|Функция|input_transaction_id BIGINT - идентификатор транзакции|Расчет объема транзакции в usdt|
|get_balance_ticker_portfolio|Функция|input_portfolio_id INT - идентификатор портфеля|Вывод криптовалют, их количества и балансов в портфеле|
|get_total_balance_user|Функция|input_user_id BIGINT - идентификатор пользователя|Вывод совокупного баланса пользователя|