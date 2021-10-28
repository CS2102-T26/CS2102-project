insert into Sessions (time, date, floor, room) values ('10:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('11:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('12:00:00', '2022-10-24', 4, 5);
insert into Sessions (time, date, floor, room) values ('13:00:00', '2022-10-24', 4, 5);
CALL book_room(4, 5, '2022-10-24', '10:00:00', '13:00:00', 261); 

-- EXPECTED PASS - meeting does not exist
CALL approve_meeting(4, 5, '2022-10-24', '08:00:00', '09:00:00', 294);

-- EXPECTED FAIL - manager not qualified to approve
CALL approve_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 299);

-- EXPECTED PASS
CALL approve_meeting(4, 5, '2022-10-24', '10:00:00', '13:00:00', 294);
SELECT * FROM approves WHERE eid = 294;
DELETE FROM approves WHERE eid = 294;
CALL approve_meeting(4, 5, '2022-10-24', '10:00:00', '15:00:00', 294);
SELECT * FROM approves WHERE eid = 294;