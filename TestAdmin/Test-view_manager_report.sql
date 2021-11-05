--EXPECTED FAIL (employee is not a manager)
select * from view_manager_report('2021-10-10', 184);
-- empty row 

--EXPECTED PASS 
--only booked sessions that are not approved
--only show same did 
 select * from view_manager_report('2021-10-10', 291);
-- 2 rows
 --can check against this
 --sessions in booked but not in approved, located in did = 1
select b.time,b.date, b.floor, b.room from books b join locatedin l on b.floor = l.floor and b.room = l.room where did = 1
except  select a.time, a.date, a.floor, a.room from approves a join locatedin l on a.floor = l.floor and a.room = l.room where did = 1;
-- sessions in booked but not in approved, without specifying did
select b.time,b.date, b.floor, b.room from books b join locatedin l on b.floor = l.floor and b.room = l.room
except  select a.time, a.date, a.floor, a.room from approves a join locatedin l on a.floor = l.floor and a.room = l.room;

-- EXPECTED FAIL (input date after all meetings date)
 select * from view_manager_report('2022-10-23', 291);