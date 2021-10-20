-- BASIC
-- add_department
CREATE OR REPLACE PROCEDURE add_department 
    (did INTEGER, dname TEXT)
AS $$
    INSERT INTO Departments (did, dname) 
    VALUES (did, dname);

$$ LANGUAGE sql;

--remove_department
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

--add_room
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

-- change capacity
-- eid added as only manager can change capacity of the room for that date
CREATE OR REPLACE PROCEDURE change_capacity(
    IN manager_id INT, IN floor_number INT, IN room_number INT, IN capacity INT, IN new_date DATE
) AS $$ 
    UPDATE Updates SET new_cap = capacity,  date = new_date 
    WHERE room = room_number 
    AND floor = floor_number
    AND eid = manager_id
    ;
$$ LANGUAGE sql;

-- add_employee
CREATE OR REPLACE PROCEDURE add_employee(
    IN e_name TEXT, IN e_home_number VARCHAR(15), IN e_mobile_number VARCHAR(15),
    IN e_office_number VARCHAR(15), IN e_type TEXT, IN e_did INT
) AS $$
DECLARE 
    unique_eid INT;
    unique_email TEXT;
BEGIN 
    -- Insert without email first, update with unique eid created
    INSERT INTO Employees (eid, ename, email, home_number, mobile_number, office_number) 
    VALUES (DEFAULT, e_name, '_@gmail.com', e_home_number, e_mobile_number, e_office_number) RETURNING eid INTO unique_eid;
    unique_email := unique_eid::TEXT || LOWER(REPLACE(e_name, ' ', '')) || '@gmail.com';
    UPDATE Employees SET email = unique_email WHERE eid = unique_eid;

    -- Insert into works in
    INSERT INTO WorksIn(eid, did) VALUES (unique_eid, e_did);

    -- Insert into either one of junior senior or manager table based on e_type
    -- need to insert into Bookers if 
    IF LOWER(e_type) = 'junior' THEN 
        INSERT INTO Juniors(eid) VALUES (unique_eid);
    ELSIF LOWER(e_type) = 'senior' THEN 
        INSERT INTO Bookers(eid) VALUES (unique_eid);
        INSERT INTO Seniors(eid) VALUES (unique_eid);  
    ELSE 
        INSERT INTO Bookers(eid) VALUES (unique_eid);
        INSERT INTO Managers(eid) VALUES (unique_eid);
    END IF;
    
END
$$ LANGUAGE plpgsql;

-- remove_employee
-- Since past records are kept, employee is kept in Employees table
-- Only assign a resigned date
CREATE OR REPLACE PROCEDURE remove_employee(
    IN e_id INT, IN last_date DATE
) AS $$
    UPDATE Employees SET resign_date = last_date 
    WHERE eid = e_id;
$$ LANGUAGE sql;

-- CORE
-- search_room

-- book_room

-- unbook_room (unbook == booker) -- approved -> remove approval --  employees joined -> removed joined employees 

-- join_meeting
-- no end_time
CREATE OR REPLACE PROCEDURE join_meeting
    (floor INTEGER, room INTEGER, date DATE, start_time TIME, end_time TIME, eid INTEGER)
AS $$
BEGIN
    WHILE start_time < end_time LOOP
        INSERT INTO Joins (eid, time, date, floor, room)
        VALUES (eid, start_time, date, floor, room);
        start_time := start_time + '01:00:00';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- leave_meeting
CREATE OR REPLACE PROCEDURE leave_meeting
    (floor INTEGER, room INTEGER, date DATE, start_time TIME, end_time TIME, eid INTEGER)
AS $$
    DECLARE
        input_floor INTEGER := floor;
        input_room INTEGER := room;
        input_date DATE := date;
        input_start_time TIME := start_time;
        input_end_time TIME := end_time;
        input_eid INTEGER := eid;
    BEGIN
        WHILE input_start_time < input_end_time LOOP
            DELETE FROM Joins j
            WHERE input_eid = j.eid AND input_start_time = j.time AND input_date = j.date
            AND input_floor = j.floor AND input_room = j.room;
            input_start_time := input_start_time + '01:00:00';
        END LOOP;
    END;
$$ LANGUAGE plpgsql;

-- approve_meeting
CREATE OR REPLACE PROCEDURE approve_meeting
    (floor INTEGER, room INTEGER, date DATE, start_time TIME, end_time TIME, eid INTEGER)
AS $$
    BEGIN
        WHILE start_time < end_time LOOP
            INSERT INTO Approves (eid, time, date, floor, room)
                VALUES (eid, start_time, date, floor, room);
            start_time := start_time + '01:00:00';
        END LOOP;    
    END;
$$ LANGUAGE plpgsql;

-- HEALTH 
-- declare_health
CREATE OR REPLACE PROCEDURE declare_health
    (eid INTEGER, date DATE, temperature NUMERIC)
AS $$
    INSERT INTO HealthDeclaration (date, temp, eid)
    VALUES (date, temperature, eid)
$$ LANGUAGE sql;

-- contact_tracing


-- ADMIN 
-- non_compliance
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

-- view_booking_report
-- find all meeting rooms booked by employee eid
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

-- view_future_meeting
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

-- view_manager_report
-- find all booked sessions that have not been approved
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
