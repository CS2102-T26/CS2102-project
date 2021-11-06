-- EXPECTED FAIL OUT OF RANGE
CALL declare_health(154, '2022-10-26', 33.9); 
CALL declare_health(154, '2022-10-26', 43.1); 

-- EXPECTED PASS  
CALL declare_health(154, '2022-10-26', 36.9); 
CALL declare_health(154, '2022-10-26', 37.9); 
CALL declare_health(154, '2022-10-26', 38.9); 

-- EXPECTED FAIL EID DOES NOT EXIST
CALL declare_health(454, '2022-10-26', 36.9); 

insert into Sessions (time, date, floor, room) values ('10:00:00', '2022-10-22', 4, 5);
CALL book_room(4, 5, '2022-10-22', '10:00:00', '11:00:00', 261); 
insert into Joins (eid, time, date, floor, room) values (13, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (174, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (124, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (116, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (165, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (134, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (154, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (145, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (164, '10:00:00', '2022-10-22', 4, 5);
insert into Approves (eid, time, date, floor, room) values (299, '10:00:00', '2022-10-22', 4, 5);

insert into Sessions (time, date, floor, room) values ('12:00:00', '2022-10-31', 4, 5);
CALL book_room(4, 5, '2022-10-31', '12:00:00', '13:00:00', 271);
insert into Joins (eid, time, date, floor, room) values (13, '12:00:00', '2022-10-31', 4, 5);
insert into Joins (eid, time, date, floor, room) values (174, '12:00:00', '2022-10-31', 4, 5);
insert into Joins (eid, time, date, floor, room) values (124, '12:00:00', '2022-10-31', 4, 5);
insert into Joins (eid, time, date, floor, room) values (116, '12:00:00', '2022-10-31', 4, 5);

insert into Sessions (time, date, floor, room) values ('13:00:00', '2022-10-31', 4, 5);
CALL book_room(4, 5, '2022-10-31', '13:00:00', '14:00:00', 261);
insert into Joins (eid, time, date, floor, room) values (15, '13:00:00', '2022-10-31', 4, 5);
insert into Joins (eid, time, date, floor, room) values (17, '13:00:00', '2022-10-31', 4, 5);
insert into Joins (eid, time, date, floor, room) values (221, '13:00:00', '2022-10-31', 4, 5);
insert into Joins (eid, time, date, floor, room) values (13, '13:00:00', '2022-10-31', 4, 5);

-- 5, 1, 5, 1 entries respectively
select * from joins where time = '12:00:00' and date = '2022-10-31' and floor = 4 and room = 5;
select * from books where time = '12:00:00' and date = '2022-10-31' and floor = 4 and room = 5;
select * from joins where time = '13:00:00' and date = '2022-10-31' and floor = 4 and room = 5;
select * from books where time = '13:00:00' and date = '2022-10-31' and floor = 4 and room = 5;

CALL declare_health(261, '2022-10-24', 37.6); 

-- 1, 1, 0, 0 entries respectively
select * from joins where time = '12:00:00' and date = '2022-10-31' and floor = 4 and room = 5;
select * from books where time = '12:00:00' and date = '2022-10-31' and floor = 4 and room = 5;
select * from joins where time = '13:00:00' and date = '2022-10-31' and floor = 4 and room = 5;
select * from books where time = '13:00:00' and date = '2022-10-31' and floor = 4 and room = 5;