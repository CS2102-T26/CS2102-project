--EXPECTED PASS (find meetings joined that have already been approved)
-- one is approved, one is not approved
call join_meeting(1,2,'2022-10-16','16:00:00','17:00:00', 13);
select * from view_future_meeting('2022-10-15', 13);
-- should have 1 row

--EXPECTED FAIL (only give output when there are meeting dates > input date)
select * from view_future_meeting('2022-10-17', 13);
-- should have no rows

