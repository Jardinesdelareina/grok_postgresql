\conect postgres

DROP DATABASE IF EXISTS med;
CREATE DATABASE med;

\connect med

DROP SCHEMA IF EXISTS test CASCADE;
CREATE SCHEMA test;


-- Валидация формы оказания помощи
CREATE DOMAIN test.valid_extr AS SMALLINT
    CHECK (VALUE IN (1, 2, 3));


CREATE TABLE test.schet
(
    code_mo VARCHAR(6) PRIMARY KEY,
    year SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    nschet VARCHAR(20),
    dschet DATE,
    plat VARCHAR(5),
    coments VARCHAR(250)
);


CREATE TABLE test.sluch
(
    id_sluch UUID PRIMARY KEY,
    pr_nov SMALLINT CHECK (pr_nov IN (1, 2)) NOT NULL,
    vidpom SMALLINT NOT NULL,
    moddate TIMESTAMPTZ NOT NULL,
    begdate TIMESTAMPTZ NOT NULL,
    enddate TIMESTAMPTZ NOT NULL,
    mo_custom VARCHAR(6) NOT NULL,
    lpubase INT NOT NULL,
    id_stat SMALLINT CHECK (id_stat IN (0, 1, 2, 3, 4, 5)) NOT NULL,
    smo VARCHAR(5),
    smo_ok VARCHAR(5),
    novor VARCHAR(9),
    lpucode INT NOT NULL,
    npr_mo VARCHAR(6),
    npr_type SMALLINT CHECK (npr_type IN (1, 2)) NOT NULL,,
    npr_midcode VARCHAR(8) NOT NULL,
    extr SMALLINT CHECK (extr IN (1, 2)) NOT NULL,
    nhistory VARCHAR(50),
    code_mes1 VARCHAR(16),
    code_mes2 VARCHAR(16),
    app_goal SMALLINT CHECK (app_goal IN (1, 2)) NOT NULL,
    rslt SMALLINT NOT NULL,
    ishold SMALLINT NOT NULL,
    vid_hmp VARCHAR(12),
    metod_hmp SMALLINT,
    prvs INT NOT NULL,
    profil VARCHAR(11) NOT NULL,
    det SMALLINT NOT NULL,
    iddokt VARCHAR(8) NOT NULL,
    povod NUMERIC(4, 2) NOT NULL,
    os_sluch SMALLINT ARRAY,
    singpay
    idsp
    grp_sk
    oplata
    ed_col
    koeffcur
    idsl
    kol_mat
    inv
    vnov
    p_per
    podr
    tal_d
    tal_p
    npr_date
    sch_code
    it_type
    srm_mark
    code_mes1
    usl_ok
    comentsl
);








CREATE OR REPLACE FUNCTION fill_field_npr_type() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.npr_mo IS NOT NULL THEN
        IF NEW.npr_type IS NULL THEN
            RAISE EXCEPTION 'Поле "Тип отправившей МО" не должно быть пустым';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_npr_mo
BEFORE INSERT OR UPDATE
ON test.sluch
FOR EACH ROW
EXECUTE FUNCTION fill_field_npr_type();