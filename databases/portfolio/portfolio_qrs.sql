-- Вывести суммарный объем торгов по buy и sell по всем тикерам за определенный промежуток времени
prepare market_value (date) as
select 
    d_symbol as symbol, 
    sum(case when d_side = 'BUY' then d_qty else 0 end) as total_buy, 
    sum(case when d_side = 'SELL' then d_qty else 0 end) as total_sell
from 
    qts.deals
where
    d_time between $1 and $2
group by
	d_symbol;

execute market_value('2024-05-30', '2024-05-31');