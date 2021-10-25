-- BASIC
-- add_department
CREATE OR REPLACE PROCEDURE add_department 
    (did INTEGER, dname TEXT)
AS $$
    INSERT INTO Departments (did, dname) VALUES (did, dname);

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
    (floor INTEGER, room INTEGER, rname TEXT, new_cap INTEGER, eid INTEGER, did INTEGER, date DATE)
AS $$
    DECLARE
        added_date DATE := '1999-12-07';
        added_eid INTEGER := 0;
    BEGIN
        INSERT INTO MeetingRooms (floor, room, rname)
        VALUES (floor, room, rname);
        INSERT INTO LocatedIn VALUES (floor, room, did);
        IF date IS NULL THEN date := added_date;
        END IF;
        IF eid IS NULL THEN eid := added_eid;
        END IF;
        INSERT INTO Updates (eid, date, new_cap, floor, room)
        VALUES (eid, date, new_cap, floor, room);

    END;
$$ LANGUAGE plpgsql;

-- change capacity
-- Insert new update; allow multiple updates
CREATE OR REPLACE PROCEDURE change_capacity(
    IN manager_id INT, IN floor_number INT, IN room_number INT, IN capacity INT, IN new_date DATE
) AS $$  
DECLARE
    update_count INT;
BEGIN 
    update_count := (SELECT COUNT(*) FROM Updates U 
                    WHERE U.date = new_date 
                    AND U.floor = floor_number 
                    AND U.room = room_number);
    IF (update_count > 0) THEN
        UPDATE Updates U SET eid = manager_id, new_cap = capacity
            WHERE U.date = new_date
            AND U.floor = floor_number 
            AND U.room = room_number;
    ELSE 
        INSERT INTO Updates (eid, date, new_cap, floor, room) 
        VALUES(manager_id, new_date, capacity, floor_number, room_number);
    END IF;
END;
$$ LANGUAGE plpgsql;

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
-- search and all rooms more than stated capacity within 
-- start_hour and end_hour that are unbooked 
-- NEED TO CHANGE
CREATE OR REPLACE FUNCTION search_room(
    IN search_capacity INT, IN search_date DATE, IN start_hour TIME, IN end_hour TIME
) RETURNS TABLE(floor_result INT, room_result INT, did_result INT, capacity_result INT)
AS $$
DECLARE
    -- table of all available sessions on that date with correct capacity
    -- ordered by capacity, room, floor, time ascending
    curs CURSOR FOR (SELECT S.floor, S.room, S.time, L.did, U.new_cap
                     FROM LocatedIn L JOIN (Sessions S JOIN Updates U
                         ON S.floor = U.floor AND S.room = U.room
                     ) ON L.floor = S.floor AND L.room = S.room
                     -- Session exists on that date
                     WHERE S.date = search_date
                     -- search capacity <= most updated capacity for that room
                     AND search_capacity <= (SELECT u.new_cap FROM Updates u2
                                            WHERE u2.date <= search_date
                                            AND u2.floor = S.floor
                                            AND u2.room = S.room
                                            ORDER BY u2.date DESC
                                            LIMIT 1)
                    AND U.date = (SELECT u3.date FROM Updates u3
                                    WHERE u3.date <= search_date
                                    AND u3.floor = S.floor
                                    AND u3.room = S.room
                                    ORDER BY u3.date DESC
                                    LIMIT 1)
                     -- Session unbooked
                     AND NOT EXISTS (
                         SELECT 1
                         FROM Books B 
                         WHERE B.floor = S.floor
                         AND B.room = S.room
                         AND B.date = S.date
                         AND B.time = S.time
                     )
                     ORDER BY U.new_cap, S.floor, S.room, S.time);
    curr RECORD;
    next RECORD;
    prevTime TIME;
BEGIN
    OPEN curs;
    LOOP
        FETCH curs INTO curr;
        EXIT WHEN NOT FOUND;
        -- Move curr until session with correct start time found
        CONTINUE WHEN curr.time <> start_hour;
        -- Means curr.time = start_hour
        -- check if 1 hour slot
        -- if 1 hr slot and curr.time = start_hour means available session
        IF start_hour = end_hour - '01:00:00' THEN
            floor_result := curr.floor;
            room_result := curr.room;
            did_result := curr.did;
            capacity_result := curr.new_cap;
            RETURN NEXT;
            CONTINUE;
        END IF;
        prevTime := start_hour;
        LOOP
            FETCH curs INTO next;
            -- Continue shifting next unless
            EXIT WHEN next.floor <> curr.floor -- diff floor
            OR next.room <> curr.room  -- diff room
            OR next.time > prevTime + '01:00:00' -- not consecutive
            OR NOT FOUND; -- end of table
            -- if next.time = end_hour - 1 => available room found
            IF next.time = end_hour - '01:00:00' THEN
                floor_result := curr.floor;
                room_result := curr.room;
                did_result := curr.did;
                capacity_result := curr.new_cap;
                RETURN NEXT;
            END IF;
            -- increment prevTime
            prevTime := next.time;
        END LOOP;
        MOVE RELATIVE -1 FROM curs;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

-- book_room
-- book all rooms between start and end hour
CREATE OR REPLACE PROCEDURE book_room(
    IN floor_number INT, IN room_number INT, IN book_date DATE, 
    IN start_hour TIME, IN end_hour TIME, IN booker_eid INT
) AS $$
DECLARE
    -- find number of available sessions for that room
    -- between start and end hour
    numSessions INT := (SELECT COUNT(*) 
                    FROM Sessions S
                    WHERE S.floor = floor_number
                    AND S.room = room_number
                    AND S.date = book_date
                    AND S.time >= start_hour
                    AND S.time < end_hour
                    AND NOT EXISTS (
                        SELECT 1
                        FROM Books B
                            WHERE floor_number = B.floor
                            AND room_number = B.room
                            AND book_date = B.date
                            AND S.time = B.time
                    ));
    tempTime TIME := start_hour;
    currTime TIME := start_hour;
BEGIN
    -- if numSessions enough; adding numSessions of 1 hr increments
    -- will be equal to end_hour; numSessions <= necessary; never over
    FOR count in 1..numSessions LOOP
        tempTime := tempTime + '01:00:00'; 
    END LOOP;
    -- if tempTime = end_hour; add all that can be added
    IF tempTime = end_hour THEN
        LOOP
            EXIT WHEN currTime = end_hour;
            -- book session
            INSERT INTO Books (eid, time, date, floor, room)
            VALUES (booker_eid, currTime, book_date, floor_number, room_number);
            -- person booking joins the meeting
            INSERT INTO Joins (eid, time, date, floor, room)
            VALUES (booker_eid, currTime, book_date, floor_number, room_number);
            currTime := currTime + '01:00:00';
        END LOOP;
        
    END IF;
END;
$$ LANGUAGE plpgsql;

-- unbook_room
-- checked employee is same employee who booked meeting
-- unbook_room (unbook == booker) -- approved -> remove approval --  employees joined -> removed joined employees 
CREATE OR REPLACE PROCEDURE unbook_room(
    IN floor_number INT, IN room_number INT, IN book_date DATE,
    IN start_hour TIME, IN end_hour TIME, IN unbooker_eid INT
) AS $$
DECLARE
    currTime TIME := start_hour;
BEGIN
    LOOP
        EXIT WHEN currTime = end_hour;
        DELETE FROM Books B
        WHERE B.eid = unbooker_eid
        AND B.floor = floor_number
        AND B.room = room_number
        AND B.time = currTime
        AND B.date = book_date;
        currTime := currTime + '01:00:00';
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- join_meeting
CREATE OR REPLACE PROCEDURE join_meeting
    (floor_number INTEGER, room_number INTEGER, join_date DATE, 
    start_time TIME, end_time TIME, joiner_eid INTEGER)
AS $$
DECLARE 
    -- find number of booked sessions for that slot
    numSessions INT := (SELECT COUNT(*)
                        FROM Books B
                        WHERE B.floor = floor_number
                        AND B.room = room_number
                        AND B.date = join_date
                        AND B.time >= start_time
                        AND B.time < end_time); 
    tempTime TIME := start_time;
BEGIN
    -- check if all sessions required are booked
    FOR count in 1..numSessions LOOP
        tempTime := tempTime + '01:00:00'; 
    END LOOP;
    -- if tempTime = end_hour; all required sessions are booked
    -- join all
    IF tempTime = end_time THEN
        LOOP
            EXIT WHEN start_time = end_time;
            INSERT INTO Joins (eid, time, date, floor, room)
            VALUES (joiner_eid, start_time, join_date, floor_number, room_number);
            start_time := start_time + '01:00:00';
        END LOOP;
    END IF;
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
    (employee_id INTEGER, declared_date DATE, declared_temperature NUMERIC)
AS $$
DECLARE
    is_updated BOOLEAN := EXISTS (SELECT 1 FROM HealthDeclaration H
                            WHERE H.eid = employee_id
                            AND H.date = declared_date);
BEGIN
    IF (is_updated) THEN
        UPDATE HealthDeclaration SET temp = declared_temperature
            WHERE eid = employee_id AND date = declared_date;
    ELSE
        INSERT INTO HealthDeclaration (date, temp, eid)
        VALUES (declared_date, declared_temperature, employee_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

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
