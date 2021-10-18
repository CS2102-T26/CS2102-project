-- BASIC add_department
CREATE OR REPLACE PROCEDURE add_department 
    (did INTEGER, dname TEXT)
AS $$
    INSERT INTO Departments (did, dname) 
    VALUES (did, dname);

$$ LANGUAGE sql;

--BASIC remove_department
CREATE OR REPLACE PROCEDURE remove_department
    (did INTEGER)
AS $$
    DECLARE
        input_did INTEGER := did;
    BEGIN
        DELETE FROM Departments d
        WHERE input_did = d.did;
    END;
$$ LANGUAGE plpgsql;

--BASIC add_room
CREATE OR REPLACE PROCEDURE add_room
    (floor INTEGER, room INTEGER, rname TEXT, new_cap INTEGER, eid INTEGER, date DATE)
AS $$
    DECLARE
        added_date DATE := '1999-12-07';
        added_eid INTEGER := 0;
    BEGIN
        INSERT INTO MeetingRooms (floor, room, rname)
        VALUES (floor, room, rname);
        IF date IS NULL THEN date := added_date;
        END IF;
        IF eid IS NULL THEN eid := added_eid;
        END IF;
        INSERT INTO Updates (eid, date, new_cap, floor, room)
        VALUES (eid, date, new_cap, floor, room);
        
    END;
$$ LANGUAGE plpgsql;


--CORE join_meeting
-- no end_time
-- check that session exists and is not approved
CREATE OR REPLACE PROCEDURE join_meeting
    (floor INTEGER, room INTEGER, date DATE, start_time TIME, eid INTEGER)
AS $$
    INSERT INTO Joins (eid, time, date, floor, room)
    VALUES (eid, start_time, date, floor, room)
$$ LANGUAGE sql;

--CORE leave_meeting
-- check that session not in approves and that eid is in meeting initially
CREATE OR REPLACE PROCEDURE leave_meeting
    (floor INTEGER, room INTEGER, date DATE, start_time TIME, eid INTEGER)
AS $$
    DECLARE
        input_floor INTEGER := floor;
        input_room INTEGER := room;
        input_date DATE := date;
        input_start_time TIME := start_time;
        input_eid INTEGER := eid;
    BEGIN
        DELETE FROM Joins j
        WHERE input_eid = j.eid AND input_start_time = j.time AND input_date = j.date
            AND input_floor = j.floor AND input_room = j.room;
    END;
$$ LANGUAGE plpgsql;

--CORE approve_meeting
CREATE OR REPLACE PROCEDURE approve_meeting
    (floor INTEGER, room INTEGER, date DATE, start_time TIME, eid INTEGER)
AS $$
    INSERT INTO Approves (eid, time, date, floor, room)
    VALUES (eid, start_time, date, floor, room)
$$ LANGUAGE sql;

--HEALTH declare_health
CREATE OR REPLACE PROCEDURE declare_health
    (eid INTEGER, date DATE, temperature NUMERIC)
AS $$
    INSERT INTO HealthDeclaration (date, temp, eid)
    VALUES (date, temperature, eid)
$$ LANGUAGE sql;

--HEALH contact_tracing


--ADMIN non_compliance
-- find eid that did not declare their temperatures once every day from 
-- start_date to end_date and the number of days that they did not declare
CREATE OR REPLACE FUNCTION non_compliance
    (IN start_date DATE, IN end_date DATE)
RETURNS TABLE(eid INTEGER, days INTEGER) AS $$
    SELECT e.eid, (end_date - start_date + 1) - COUNT(distinct hd.date) AS days
    FROM Employees e LEFT OUTER JOIN HealthDeclaration hd
    ON e.eid = hd.eid AND (hd.date >= start_date
    AND hd.date <= end_date)
    GROUP BY e.eid
    HAVING COUNT(distinct hd.date) < (end_date - start_date + 1)
    ORDER BY days DESC
$$ LANGUAGE sql;

--ADMIN view_booking_report
--find all meeting rooms booked by employee eid
CREATE OR REPLACE FUNCTION view_booking_report
    (IN start_date DATE, IN input_eid INTEGER)
RETURNS TABLE(floor INTEGER, room INTEGER, date DATE, start_hour TIME, is_approved TEXT) AS $$
    SELECT b.floor, b.room, b.date, b.time, CASE 
        WHEN a.time IS NULL THEN 'Not Approved'
        ELSE 'Approved' END AS is_approved
    FROM (Employees e JOIN Books b
    ON e.eid = b.eid) LEFT OUTER JOIN Approves a
    ON b.floor = a.floor AND b.room = a.room AND b.date = a.date AND b.time = a.time
    WHERE b.date >= start_date AND input_eid = e.eid
    ORDER BY b.date, b.time ASC
$$ LANGUAGE sql;


--ADMIN view_future_meeting
-- find all approved future meetings employee eid is going to have
CREATE OR REPLACE FUNCTION view_future_meeting
    (IN start_date DATE, IN input_eid INTEGER)
RETURNS TABLE(floor INTEGER, room INTEGER, date DATE, start_hour TIME) AS $$
    SELECT j.floor, j.room, j.date, j.time
    FROM (Employees e JOIN Joins j
    ON e.eid = j.eid) JOIN Approves a
    ON j.floor = a.floor AND j.room = a.room AND j.date = a.date AND j.time = a.time
    WHERE j.date >= start_date AND input_eid = e.eid
    ORDER BY j.date, j.time ASC
$$ LANGUAGE sql;

--ADMIN view_manager_report
--find all booked sessions that have not been approved
-- if eid not in Managers then return empty table
CREATE OR REPLACE FUNCTION view_manager_report
    (IN start_date DATE, IN input_eid INTEGER)
RETURNS TABLE(floor INTEGER, room INTEGER, date DATE, start_hour TIME, eid INTEGER) AS $$
    SELECT b.floor, b.room, b.date, b.time, input_eid 
    FROM Books b LEFT OUTER JOIN Approves a
    ON b.floor = a.floor AND b.room = a.room AND b.date = a.date AND b.time = a.time
    WHERE b.date >= start_date AND a.floor IS NULL AND input_eid IN (SELECT m.eid 
                                                                    FROM Managers m)
    ORDER BY b.date, b.time ASC
$$ LANGUAGE sql;
