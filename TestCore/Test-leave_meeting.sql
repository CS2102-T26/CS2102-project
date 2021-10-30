insert into Sessions (time, date, floor, room) values ('10:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('11:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('12:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('13:00:00', '2022-10-24', 4, 5);
CALL unbook_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261);
CALL book_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261); 
CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 11);
CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 12);
CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 13);
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

-- EXPECTED PASS 11 leaves
CALL leave_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 11);
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

-- EXPECTED PASS 12 leaves the 1st hour
CALL leave_meeting(4, 5, '2022-10-24', '10:00:00', '11:00:00', 12);
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

-- EXPECTED FAIL 111 is not in meeting
CALL leave_meeting(4, 5, '2022-10-24', '10:00:00', '11:00:00', 111);
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

-- EXPECTED PASS 13 leaves whole meeting
CALL leave_meeting(4, 5, '2022-10-24', '10:00:00', '16:00:00', 13);
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

-- EXPECTED PASS 261 leaves, meeting no longer booked, 12 leaves as well since meeting no longer exists
CALL leave_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261);
SELECT * FROM books WHERE eid = 261;
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

insert into Sessions (time, date, floor, room) values ('10:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('11:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('12:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('13:00:00', '2022-10-24', 4, 5);
CALL unbook_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261);
CALL book_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261); 
CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 11);
CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 12);
CALL join_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 13);
CALL approve_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 299);
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';

-- EXPECTED FAIL meeting is approved
CALL leave_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261);
SELECT * FROM books WHERE eid = 261;
SELECT * FROM joins WHERE floor = 4 AND room = 5 AND date = '2022-10-24';
