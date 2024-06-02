-- Вывести суммарный объем торгов по buy и sell по всем тикерам за определенный промежуток времени
prepare market_value (date) as
select 
    d_symbol as symbol, 
    sum(d_qty) filter (where d_side = 'BUY') as total_buy, 
    sum(d_qty) filter (where d_side = 'SELL') as total_sell
from 
    qts.deals
where
    d_time between $1 and $2
group by
	d_symbol;

execute market_value('2024-05-30', '2024-05-31');