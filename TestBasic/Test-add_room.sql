-- EXPECTED PASS
CALL add_room(7, 1, 'Room 7-1', 10, 306, 13, null);
CALL add_room(7, 2, 'Room 7-2', 10, 306, 13, null);
CALL add_room(7, 3, 'Room 7-3', 10, 306, 13, null);
CALL add_room(8, 1, 'Room 8-1', 5, 309, 14, null);
CALL add_room(8, 2, 'Room 8-2', 5, 309, 14, null);
CALL add_room(8, 3, 'Room 8-3', 5, 309, 14, null);

-- EXPECTED FAIL
-- NULL floor
CALL add_room(NULL, 1, 'Room N-1', 10, 306, 13, null);

-- NULL room
CALL add_room(9, NULL, 'Room N-1', 10, 306, 13, null);

-- NULL rname
CALL add_room(9, 1, NULL, 10, 306, 13, null);

-- NULL CAP
CALL add_room(9, 1, 'Room N-1', NULL, 306, 13, null);

-- NULL did
CALL add_room(9, 1, 'Room N-1', 10, 306, NULL, null);

-- EXPECTED FAIL
-- SAME, ROOM FLOOR
CALL add_room(7, 1, 'NEW ROOM', 10, 306, 13, null);