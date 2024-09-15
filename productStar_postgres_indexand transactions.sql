/*Напишите SQL-скрипт, который потокобезопасно в рамках транзакции создает новое бронирование. Скрипт должен включать:
    Создание нового бронирования.
    Создание нового билета.
    Привязка билета к перелету.*/


begin transaction;
do
$$
	declare 
		booking_r varchar(6) = '123456';
		ticket_num varchar(13) = '1111222233';
	begin
		insert into bookings(book_ref, book_date, total_amount)
		values (booking_r, current_date, 42069);
	
		insert into tickets (ticket_no, book_ref, passenger_id, passenger_name, contact_data)
		values (ticket_num, booking_r, 1, 'DMITRIY PAKHOTNOV', '{"passport": "yes", "sex": "no"}');
	
		insert into ticket_flights (ticket_no, flight_id, fare_conditions, amount)
		values (ticket_num, 1228, 'Comfort', 5000);
	end	
$$;
commit;


/*Напишите SQL-скрипт, который потокобезопасно в рамках транзакции оформляет посадку пассажира на самолет. Скрипт должен включать:
    Проверку существования рейса.
    Проверку билета у пассажира на рейс.
    Создание нового посадочного талона.*/

begin transaction;
do
$$
	declare 
		ticket_num varchar(13);
		flight_num int;
	begin

		select t.ticket_no 
		into ticket_num
		from tickets t 
		where t.passenger_name = 'DMITRIY PAKHOTNOV';
		
		select tf.flight_id 
		into ticket_num
		from ticket_flights tf 
		where tf.ticket_no = ticket_num;
		
		if not exists
		(select 1
		from boarding_passes s
		where s.ticket_no = ticket_num 
		and s.flight_id = ticket_num)
		then
			insert into boarding_passes (ticket_no, flight_id, boarding_no, seat_no)
			select ticket_num, ticket_num, 1, s2.seat_no 
			from seats s2
			where s2.fare_conditions = 'Comfort'
			limit 1;
		
			raise info 'Посадочный создан!';
		
		end if;	
	end	
$$;
commit;

----------------------------------------------------------------------------------------------------------------------------------
/*Напишите запрос для поиска билетов по имени пассажиров. Оптимизируйте скорость его выполнения.
    Приложите результаты выполнения команд EXPLAIN ANALYZE до и после оптимизации.*/
	
	explain analyze
	select *
	from tickets t 
	where t.passenger_name ilike 'DMITRIY PAKHOTNOV'
	
	/*"Gather  (cost=1000.00..71716.74 rows=59129 width=104) (actual time=7.426..6357.156 rows=62988 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Parallel Seq Scan on tickets t  (cost=0.00..64803.84 rows=24637 width=104) (actual time=3.110..6298.711 rows=20996 loops=3)"
"        Filter: (passenger_name ~~* 'DMITRIY%'::text)"
"        Rows Removed by Filter: 962290"
"Planning Time: 3.128 ms"
"Execution Time: 6361.857 ms"*/
	
	/*проверка работы индекса на примере таблицы с пассажирами*/
	DROP INDEX idx_tickets_passenger_index;*/

	CREATE INDEX idx_tickets_passenger_index ON tickets(passenger_name);
	explain analyze
	select *
	from tickets t 
	where t.passenger_name ilike 'DMITRIY PAKHOTNOV'
	
	
/*
"Gather  (cost=1000.00..71716.74 rows=59129 width=104) (actual time=0.507..3056.539 rows=62988 loops=1)"
"  Workers Planned: 2"
"  Workers Launched: 2"
"  ->  Parallel Seq Scan on tickets t  (cost=0.00..64803.84 rows=24637 width=104) (actual time=0.536..3003.889 rows=20996 loops=3)"
"        Filter: (passenger_name ~~* 'DMITRIY%'::text)"
"        Rows Removed by Filter: 962290"
"Planning Time: 7.784 ms"
"Execution Time: 3060.428 ms"*/


