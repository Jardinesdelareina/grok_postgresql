-- Количество человек, которое бывает включено в одно бронирование
select count(ticket_no) as count_tickets from Tickets group by book_ref;


-- Города, до которых не добраться без пересадок из Москвы
select distinct 
    arrival_city as curr_city 
from 
    (select a.city as departure_city, b.city as arrival_city
    from Flights
    join Airports a on Flights.departure_airport = a.airport_code
    join Airports b on Flights.arrival_airport = b.airport_code) as subquery 
where 
    departure_city = 'Москва' order by curr_city;


-- Модель самолета, выполняющая максимальное число рейсов
with count_fl as 
    (select distinct model, count(Flights.flight_id) as cnt 
    from Aircrafts 
    join Flights on Aircrafts.aircraft_code = Flights.aircraft_code 
    group by model) 
select model 
from count_fl 
where cnt = (select max(cnt) from count_fl);


-- Модель, перевозящая больше всего пассажиров
with count_passengers as 
    (select model, count(passenger_id) as passengers
    from (select *
        from Aircrafts
        join Flights on Aircrafts.aircraft_code = Flights.aircraft_code) as models_aircrafts
    join (select *
        from Ticket_flights
        join Tickets on Ticket_flights.ticket_no = Tickets.ticket_no) as tickets
    on models_aircrafts.flight_id = tickets.flight_id
    group by model)
select model
from count_passengers
where passengers = (select max(passengers) from count_passengers);