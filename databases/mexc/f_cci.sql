CREATE OR REPLACE FUNCTION cci_value(period INTEGER) RETURNS NUMERIC AS $$
    DECLARE
        price_high NUMERIC;
        price_low NUMERIC;
        price_close NUMERIC;
        typical_price NUMERIC;
        average NUMERIC;
        sma NUMERIC;
        mean NUMERIC;
        cci NUMERIC;
    BEGIN
        price_high := (SELECT m_high FROM xrpusdt ORDER BY m_time DESC LIMIT 1);
        price_low := (SELECT m_low FROM xrpusdt ORDER BY m_time DESC LIMIT 1);
        price_close := (SELECT m_close FROM xrpusdt ORDER BY m_time DESC LIMIT 1);
        average := (SELECT AVG(typical_price) FROM xrpusdt ORDER BY m_time LIMIT period);

        typical_price := (price_high + price_low + price_close) / 3;
        sma := (SELECT AVG(typical_price) FROM average);
        mean := (SELECT AVG(ABC(typical_price - sma)) FROM average);
        cci := (typical_price - sma) / (0.015 * mean);
    RETURN cci;
    END
$$ LANGUAGE plpgsql;

SELECT cci_value(14);