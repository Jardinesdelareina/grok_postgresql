-- Количество человек, которое бывает включено в одно бронирование
select count(ticket_no) as count_tickets from Tickets group by book_ref;