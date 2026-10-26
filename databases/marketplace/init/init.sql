\connect postgres

drop database if exists marketplace with (force);
create database marketplace;

\connect marketplace


create extension if not exists pg_stat_statements; 
create extension if not exists pgcrypto;
create role role_mp with login password '1234';
create schema if not exists mpcore;
create schema if not exists mpdir;
grant usage on schema mpcore to role_mp;
grant usage on schema mpdir to role_mp;


-- Справочник: Тип аккаунта
create table if not exists mpdir.dir_acc_type
(
    acc_type_id     smallint        generated always as identity primary key,
    acc_type_code   varchar         unique not null,
    acc_type_name   varchar         unique not null
);

alter table mpdir.dir_acc_type owner to role_mp;

insert into mpdir.dir_acc_type(acc_type_code, acc_type_name)
values('1', 'Администрация'), ('2', 'Продавец'), ('3', 'Покупатель');


-- Справочник: Города
create table if not exists mpdir.dir_cities
(
    cit_id          smallint        generated always as identity primary key,
    cit_code        varchar         unique not null,
    cit_name        varchar         unique not null,
    time_from       timestamptz     default now(),
    time_to         timestamptz
);

alter table mpdir.dir_cities owner to role_mp;

do $$
declare
    city_names text[] := array[
        'Москва', 'Санкт-Петербург', 'Новосибирск', 'Екатеринбург', 'Казань',
        'Нижний Новгород', 'Челябинск', 'Краснодар', 'Самара', 'Омск',
        'Ростов-на-Дону', 'Уфа', 'Красноярск', 'Воронеж', 'Пермь',
        'Волгоград', 'Саратов', 'Тюмень', 'Тольятти', 'Ижевск',
        'Барнаул', 'Ульяновск', 'Иркутск', 'Хабаровск', 'Ярославль',
        'Владивосток', 'Махачкала', 'Томск', 'Оренбург', 'Кемерово',
        'Новокузнецк', 'Рязань', 'Астрахань', 'Пенза', 'Липецк',
        'Киров', 'Чебоксары', 'Тула', 'Калининград', 'Балашиха',
        'Курск', 'Севастополь', 'Сочи', 'Ставрополь', 'Тверь',
        'Магнитогорск', 'Иваново', 'Брянск', 'Белгород', 'Сургут',
        'Владимир', 'Нижний Тагил', 'Архангельск', 'Чита', 'Калуга',
        'Смоленск', 'Волжский', 'Череповец', 'Вологда', 'Саранск',
        'Курган', 'Орёл', 'Мурманск', 'Якутск', 'Тамбов',
        'Стерлитамак', 'Грозный', 'Кострома', 'Петрозаводск', 'Нижневартовск',
        'Новороссийск', 'Химки', 'Таганрог', 'Комсомольск-на-Амуре', 'Шахты',
        'Дзержинск', 'Орск', 'Братск', 'Ангарск', 'Благовещенск',
        'Старый Оскол', 'Кызыл', 'Великий Новгород', 'Королёв', 'Псков',
        'Бийск', 'Прокопьевск', 'Рыбинск', 'Северодвинск', 'Армавир',
        'Подольск', 'Нефтекамск', 'Хасавюрт', 'Коломна', 'Майкоп',
        'Одинцово', 'Домодедово', 'Каспийск', 'Нефтеюганск', 'Кисловодск',
        'Серпухов', 'Первоуральск', 'Новочеркасск', 'Обнинск', 'Каменск-Уральский',
        'Зеленодольск', 'Новый Уренгой', 'Салават', 'Ноябрьск', 'Муром',
        'Камышин', 'Волгодонск', 'Серов', 'Новочебоксарск', 'Березники',
        'Железногорск', 'Миасс', 'Батайск', 'Копейск', 'Электросталь',
        'Люберцы', 'Красногорск', 'Мурино', 'Кудрово', 'Зеленоград',
        'Азов', 'Алексин', 'Альметьевск', 'Анжеро-Судженск', 'Арамиль',
        'Арзамас', 'Артём', 'Асбест', 'Балаково', 'Барабинск',
        'Белебей', 'Белово', 'Белогорск', 'Белорецк', 'Белореченск',
        'Бердск', 'Биробиджан', 'Бирск', 'Бор', 'Борисоглебск',
        'Будённовск', 'Буйнакск', 'Чайковский', 'Чапаевск', 'Черкесск',
        'Черногорск', 'Чистополь', 'Дмитров', 'Дубна', 'Егорьевск',
        'Ессентуки', 'Гатчина', 'Геленджик', 'Глазов', 'Горно-Алтайск',
        'Губкин', 'Гусь-Хрустальный', 'Ивантеевка', 'Избербаш', 'Кашира',
        'Кинешма', 'Кинель', 'Кириши', 'Киселёвск', 'Клин'
    ];
    i int;
begin
    for i in 1..array_length(city_names, 1) loop
        insert into mpdir.dir_cities (cit_code, cit_name)
        values (
            'C' || lpad(i::text, 3, '0'),
            city_names[i]
        )
        on conflict (cit_name) do nothing;
    end loop;
end $$;

-- Справочник: Статусы
create table if not exists mpdir.dir_statuses
(
    stat_id         smallint        generated always as identity primary key,
    status_type     varchar         not null,
    status_code     varchar         not null,
    status_name     varchar         not null
);

alter table mpdir.dir_statuses owner to role_mp;

do $$
declare
    statuses text[][] := array[
        ['order', 'paid', 'Оплачен'],
        ['order', 'processing', 'В обработке'],
        ['order', 'cancelled', 'Отменён'],
        ['payment', 'pending', 'Ожидает подтверждения'],
        ['payment', 'captured', 'Подтвержден'],
        ['payment', 'cancelled', 'Отменён']
    ];
    i int;
begin
    for i in 1..array_length(statuses, 1) loop
        insert into mpdir.dir_statuses (status_type, status_code, status_name)
        values (
            statuses[i][1],
            statuses[i][2],
            statuses[i][3]
        );
    end loop;
end $$;

-- Справочник: Категории товаров
create table if not exists mpdir.dir_categories
(
    cat_id          smallint        generated always as identity primary key,
    cat_code        varchar         unique not null,
    cat_name        varchar         not null,
    cat_path        text            unique not null,
    time_from       timestamptz     default now(),
    time_to         timestamptz
);

alter table mpdir.dir_categories owner to role_mp;

do $$
declare
    cats text[][] := array[
        ['1','Электроника'],
        ['2','Одежда и обувь'],
        ['3','Дом и сад'],
        ['4','Красота и здоровье'],
        ['5','Спорт и отдых'],
        ['6','Детские товары'],
        ['7','Авто и мото'],
        ['8','Книги и канцтовары'],
        ['9','Продукты питания'],
        ['10','Зоотовары'],
        ['1:1','Смартфоны и планшеты'],
        ['1:2','Ноутбуки и компьютеры'],
        ['1:3','Телевизоры и аудио'],
        ['1:4','Бытовая техника'],
        ['1:5','Фото и видео'],
        ['1:6','Игровые консоли'],
        ['1:1:1','Смартфоны'],
        ['1:1:2','Планшеты'],
        ['1:1:3','Аксессуары для смартфонов'],
        ['1:2:1','Ноутбуки'],
        ['1:2:2','Настольные ПК'],
        ['1:2:3','Мониторы'],
        ['1:2:4','Комплектующие'],
        ['1:2:5','Периферия'],
        ['1:3:1','Телевизоры'],
        ['1:3:2','Наушники'],
        ['1:3:3','Акустические системы'],
        ['1:4:1','Крупная бытовая техника'],
        ['1:4:2','Мелкая бытовая техника'],
        ['1:4:3','Климатическая техника'],
        ['1:5:1','Фотоаппараты'],
        ['1:5:2','Видеокамеры'],
        ['1:5:3','Объективы'],
        ['1:6:1','Консоли'],
        ['1:6:2','Игры для консолей'],
        ['1:6:3','Аксессуары для консолей'],
        ['2:1','Мужская одежда'],
        ['2:2','Женская одежда'],
        ['2:3','Детская одежда'],
        ['2:4','Обувь'],
        ['2:5','Аксессуары'],
        ['2:1:1','Футболки и рубашки'],
        ['2:1:2','Брюки и джинсы'],
        ['2:1:3','Верхняя одежда'],
        ['2:2:1','Платья и юбки'],
        ['2:2:2','Блузки и топы'],
        ['2:2:3','Верхняя одежда'],
        ['2:4:1','Кроссовки и кеды'],
        ['2:4:2','Ботинки и сапоги'],
        ['2:4:3','Туфли и сандалии'],
        ['3:1','Мебель'],
        ['3:2','Освещение'],
        ['3:3','Текстиль'],
        ['3:4','Посуда и кухня'],
        ['3:5','Сад и огород'],
        ['3:1:1','Мягкая мебель'],
        ['3:1:2','Корпусная мебель'],
        ['3:1:3','Столы и стулья'],
        ['3:4:1','Кастрюли и сковороды'],
        ['3:4:2','Столовые приборы'],
        ['3:4:3','Кухонные принадлежности'],
        ['4:1','Уход за кожей'],
        ['4:2','Уход за волосами'],
        ['4:3','Парфюмерия'],
        ['4:4','Здоровье и медицина'],
        ['5:1','Фитнес и тренажёры'],
        ['5:2','Туризм и кемпинг'],
        ['5:3','Велосипеды и самокаты'],
        ['5:4','Командные виды спорта'],
        ['6:1','Игрушки'],
        ['6:2','Детское питание'],
        ['6:3','Детская мебель'],
        ['6:4','Подгузники и гигиена'],
        ['7:1','Автомобили'],
        ['7:2','Мотоциклы'],
        ['7:3','Автозапчасти'],
        ['7:4','Автоаксессуары'],
        ['8:1','Книги'],
        ['8:2','Канцтовары'],
        ['8:3','Учебная литература'],
        ['9:1','Бакалея'],
        ['9:2','Напитки'],
        ['9:3','Снеки и сладости'],
        ['10:1','Корма для животных'],
        ['10:2','Аксессуары для животных'],
        ['10:3','Ветаптека']
    ];
    i int;
begin
    for i in 1..array_length(cats, 1) loop
        insert into mpdir.dir_categories (cat_code, cat_name, cat_path)
        values (
            'CAT' || lpad(i::text, 3, '0'),
            cats[i][2],
            cats[i][1]
        )
        on conflict (cat_path) do nothing;
    end loop;
end $$;


-- Пользователи
create table if not exists mpcore.users 
(
    us_id           bigint          generated always as identity primary key,
    first_name      text            not null,
    last_name       text            not null,
    phone_number    text            unique not null,
    cit_code        text            not null,
    balance         numeric(12, 2)  default 0,
    acc_type_code   varchar         not null,
    json_data       jsonb,           

    create_date     timestamptz     default now(),
    created_by      text,
    update_date     timestamptz,
    updated_by      text,
    delete_date     timestamptz,
    deleted_by      text
);

alter table mpcore.users owner to role_mp;

create index if not exists users_phone_idx on mpcore.users(phone_number);


-- Товары
create table if not exists mpcore.products
(
    pr_id           bigint          generated always as identity primary key,
    us_id           bigint          not null references mpcore.users(us_id),
    cat_id          bigint          not null,
    pr_num          varchar         not null,
    pr_name         varchar         not null,
    cnt_pr          int             not null,
    price           numeric(12, 2)  not null check (price >= 0),
    json_data       jsonb,

    create_date     timestamptz     default now(),
    created_by      text,
    update_date     timestamptz,
    updated_by      text,
    delete_date     timestamptz,
    deleted_by      text
);

alter table mpcore.products owner to role_mp;


-- Заказы
create table if not exists mpcore.orders 
(
    o_id            bigint          generated always as identity,
    us_id           bigint          not null references mpcore.users(us_id),
    status_code     varchar         not null,
    cart_json       text            not null,
    total_amount    numeric(12, 2)  default 0,

    create_date     timestamptz     default now(),
    created_by      text,
    update_date     timestamptz,
    updated_by      text,
    delete_date     timestamptz,
    deleted_by      text,
    primary key (o_id, create_date)
);-- partition by range (create_date);

alter table mpcore.orders owner to role_mp;

/*
do $$
declare
    start_date date := '2025-01-01';
    i int;
    part_start date;
    part_end   date;
begin
    for i in 0..23 loop
        part_start := start_date + (i || ' month')::interval;
        part_end   := part_start + interval '1 month';
        execute format(
            'create table if not exists mpcore.orders_%s partition of mpcore.orders for values from (%L) to (%L);',
            to_char(part_start, 'YYYY_MM'),
            part_start, part_end
        );
    end loop;
end $$;
*/
create index if not exists orders_status_idx on mpcore.orders(status_code);
create index if not exists orders_created_date_idx on mpcore.orders(create_date);


-- Платежи
create table if not exists mpcore.payments 
(
    pay_id              bigint          generated always as identity,
    o_id                bigint          not null,
    status_code         text            not null,

    create_date         timestamptz     default now(),
    created_by          text,
    update_date         timestamptz,
    updated_by          text,
    delete_date         timestamptz,
    deleted_by          text,
    foreign key (o_id, order_create_date) references mpcore.orders(o_id, create_date)
);

alter table mpcore.payments owner to role_mp;


------------------------------------
------------------------------------
------------------------------------

\ir procedures/user_create.sql
\ir procedures/user_edit.sql
\ir procedures/user_del.sql
\ir procedures/product_create.sql
\ir procedures/product_edit.sql
\ir procedures/product_del.sql
\ir procedures/order_create.sql
\ir procedures/order_edit.sql
\ir procedures/order_del.sql
\ir procedures/payment_create.sql