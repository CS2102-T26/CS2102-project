-- Q1 EXPECTED PASS (has results for past data)
select * from search_room(3, '2021-10-02', '16:00:00', '19:00:00');

-- Q2 EXPECTED PASS (for future data)
select * from search_room(1, '2022-10-26', '16:00:00', '19:00:00');

-- Test with change_capacity, make sure is ascending
call change_capacity(298, 4, 1, 15, current_date);
select * from search_room(3, current_date + 1, '16:00:00', '19:00:00');
call change_capacity(299, 2, 2, 10, current_date);
select * from search_room(3, current_date + 1, '16:00:00', '19:00:00');
call change_capacity(298, 4, 1, 5, current_date);
select * from search_room(3, current_date + 1, '16:00:00', '19:00:00');

-- EXPECTED NO RESULTS FOR APPROVED ROOM
select * from search_room(1, '2022-10-17', '10:00:00', '11:00:00');