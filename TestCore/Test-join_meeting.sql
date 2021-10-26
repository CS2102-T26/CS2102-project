-- EXPECTED PASS - 1h slot
CALL join_meeting(4, 1, '2022-10-26', '16:00:00', '17:00:00', 4);
SELECT * FROM Joins WHERE eid = 4;

-- EXPECTED PASS - >1h different room
CALL join_meeting(4, 1, '2022-10-26', '16:00:00', '18:00:00', 5);
SELECT * FROM Joins WHERE eid = 5;

-- EXPECTED FAIL - fever
CALL join_meeting(4, 1, '2022-10-26', '16:00:00', '17:00:00', 277); -- fever in book room
SELECT * FROM Joins WHERE eid = 277;

-- EXPECTED FAIL - exceed meeting time (meeting 1600-1800, join 1700-1900)
CALL join_meeting(4, 1, '2022-10-26', '17:00:00', '19:00:00', 14);

-- EXPECTED FAIL - overcapacity last person (inclusive of booker 298, 4, 5)
CALL join_meeting(4, 1, '2022-10-26', '16:00:00', '17:00:00', 11);
CALL join_meeting(4, 1, '2022-10-26', '16:00:00', '17:00:00', 12);
CALL join_meeting(4, 1, '2022-10-26', '16:00:00', '17:00:00', 13);
SELECT * FROM Joins WHERE floor = 4 AND room = 1;

-- EXPECTED FAIL - approved meeting cannot join
CALL approve_meeting(4, 1, '2022-10-26', '17:00:00', '18:00:00', 308);
CALL join_meeting(4, 1, '2022-10-26', '17:00:00', '18:00:00', 15);
SELECT * FROM Joins WHERE floor = 4 AND room = 1;

-- EXPECTED FAIL - join session instead of booking
CALL join_meeting(4, 3, '2022-10-20', '16:00:00', '17:00:00', 16);
SELECT * FROM Joins WHERE floor = 4 AND room = 3;