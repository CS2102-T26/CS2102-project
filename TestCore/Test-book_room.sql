-- EXPECTED PASS
CALL book_room(4, 1, '2022-10-26', '16:00:00', '17:00:00', 298); -- manager
CALL book_room(4, 1, '2022-10-26', '17:00:00', '18:00:00', 252); -- senior
CALL book_room(2, 2, '2022-10-26', '18:00:00', '19:00:00', 298); -- manager

-- EXPECTED PASS
CALL book_room(4, 1, '2022-10-28', '17:00:00', '18:00:00', 298); -- manager

-- EXPECTED FAIL - cannot book all slots
CALL book_room(4, 1, '2022-10-28', '16:00:00', '19:00:00', 252); -- manager

-- EXPECTED FAIL BOOK PAST  
CALL book_room(4, 1, '2021-10-02', '16:00:00', '18:00:00', 298);
CALL book_room(4, 1, '2021-10-02', '18:00:00', '19:00:00', 275);

-- EXPECTED FAIL JUNIOR BOOK
CALL book_room(2, 2, '2022-10-26', '16:00:00', '17:00:00', 1);

-- EXPECTED FAIL (FEVER BOOK)
CALL declare_health(277, current_date, 38.0);
CALL book_room(2, 1, current_date + 1, '16:00:00', '17:00:00', 277);

-- EXPECTED FAIL (RESIGNED SENIOR)
CALL book_room(2, 2, '2022-10-26', '18:00:00', '19:00:00', 285); -- senior

SELECT * FROM Books ORDER BY date, time;