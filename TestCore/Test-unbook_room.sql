insert into Sessions (time, date, floor, room) values ('10:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('11:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('12:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('13:00:00', '2022-10-24', 4, 5);
CALL unbook_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261);
CALL book_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261); 
SELECT * FROM books WHERE eid = 261;

-- EXPECTED FAIL different employee
CALL unbook_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 244);
SELECT * FROM books WHERE eid = 261;

CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 11);
CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 12);
CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 13);
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

-- EXPECTED PASS
CALL unbook_room(4, 5, '2022-10-24', '10:00:00', '11:00:00', 261);
SELECT * FROM books WHERE eid = 261;
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

-- EXPECTED PASS no more entries left in table
CALL unbook_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261);
SELECT * FROM books WHERE eid = 261;
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';