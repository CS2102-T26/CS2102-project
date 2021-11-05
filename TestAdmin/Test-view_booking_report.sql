CALL book_room(4, 1, '2022-10-26', '16:00:00', '17:00:00', 298); -- manager
CALL book_room(4, 1, '2022-10-26', '17:00:00', '18:00:00', 252); -- senior
CALL book_room(2, 2, '2022-10-26', '18:00:00', '19:00:00', 298); -- manager
CALL book_room(4, 1, '2022-10-28', '17:00:00', '18:00:00', 298); -- manager

-- Expected pass (All bookings after date showed; all unapproved)
select * from view_booking_report('2022-10-25', 298);

-- Expected pass (approved booking)
call approve_meeting(4, 1, '2022-10-26', '16:00:00', '17:00:00', 308);
select * from view_booking_report('2022-10-25', 298);

-- Expected pass (dates before start date input not shown)
-- bookings on 26th not shown, only booking on 28th shown
select * from view_booking_report('2022-10-27', 298);

-- Expected fail (no meetings booked by senior or manager => 0 rows)
select * from view_booking_report('2022-10-25', 254);
select * from view_booking_report('2022-10-25', 308);
