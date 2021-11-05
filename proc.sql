-- Triggers

-- Trigger function removing any room booked with number of 
-- employees in meeting over the new capacity after update date
CREATE OR REPLACE FUNCTION remove_bookings_over_capacity() RETURNS TRIGGER AS $$
DECLARE 
    -- select upper bound date; furthest update date for that room
    upperBoundDate DATE := (SELECT MAX(U.date) 
                            FROM Updates U
                            WHERE U.floor = NEW.floor
                            AND U.room = NEW.room);
    -- Selects all booked meetings with capacity over new_capacity 
    -- for room where capacity was changed
    curs CURSOR FOR (SELECT B.time, B.date, B.floor, B.room, COUNT(J.eid)
                    FROM Books B JOIN Joins J 
                        ON B.time = J.time AND B.date = J.date
                           AND B.floor = J.floor AND B.room = J.room
                    WHERE B.floor = NEW.floor AND B.room = NEW.room 
                    AND (
                    -- new updated date is new max date; find all bookings after this date
                    (NEW.date >= upperBoundDate AND B.date >= NEW.date)
                     OR 
                    -- new updated date is before curr max date; find all booking in between
                    (NEW.date <= upperBoundDate AND B.date >= NEW.date AND B.date < upperBoundDate)
                    )
                    GROUP BY B.time, B.date, B.floor, B.room
                    HAVING COUNT(J.eid) > NEW.new_cap);
    r1 RECORD;
BEGIN
    OPEN curs;
    LOOP
        -- EXIT WHEN NO MORE ROWS
        FETCH curs INTO r1;
        EXIT WHEN NOT FOUND;
        -- DELETE from Books 
        DELETE FROM Books B1
        WHERE B1.time = r1.time 
        AND B1.date = r1.date
        AND  B1.floor = r1.floor
        AND B1.room = r1.room;
    END LOOP;
    CLOSE curs;
    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;

-- Trigger to remove all sessions not meeting requirements after new cap insert
DROP TRIGGER IF EXISTS capacity_updated ON Updates;
CREATE TRIGGER capacity_updated
AFTER INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION remove_bookings_over_capacity();


-- Trigger on UPDATE of Employee resign_date
-- Remove All meetings joined, booked or approved after employees resign date
CREATE OR REPLACE FUNCTION remove_from_future_records() RETURNS TRIGGER AS $$
BEGIN
    -- Remove from Joins if date is after or on resigned_date
    DELETE FROM Joins J 
    WHERE J.eid = NEW.eid
    AND J.date >= NEW.resign_date;
    -- DELETE from Books; If inside will be deleted
    DELETE FROM Books B 
    WHERE B.eid = NEW.eid
    AND B.date >= NEW.resign_date;
    -- DELETE from Approves; If inside will be deleted
    DELETE FROM Approves A 
    WHERE A.eid = NEW.eid
    AND A.date >= NEW.resign_date;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS employee_resigned ON Employees;
CREATE TRIGGER employee_resigned
AFTER UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION remove_from_future_records();

-- Trigger Function for checking if employee attempting to join / book / approves is still
-- working for the company
CREATE OR REPLACE FUNCTION check_if_resigned() RETURNS TRIGGER AS $$
DECLARE
    e_left_date DATE;
BEGIN
    -- get date of employee joining, booking or adding
    SELECT resign_date INTO e_left_date FROM Employees WHERE eid = NEW.eid;
    -- Return null if no longer working there; resigned_date < date
    IF e_left_date IS NOT NULL AND NEW.date > e_left_date THEN RETURN NULL;
    END IF;
    -- join / book / approve
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger(s) for joining meeting;
-- check that 
-- employee is still working for company [DONE]
-- session has been booked [DONE]
-- session has not past [DONE in check constraint]
-- session has not been approved [DONE]
-- not over capacity [BORY] [DONE]

CREATE OR REPLACE FUNCTION check_time_clash_before_join() RETURNS TRIGGER AS $$
DECLARE
BEGIN
    IF EXISTS(SELECT 1
            FROM joins j
            WHERE j.eid = NEW.eid
            AND j.time = NEW.time
            AND j.date = NEW.date)  
            THEN RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_time_clash_for_join ON Joins;
CREATE TRIGGER check_time_clash_for_join
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION check_time_clash_before_join();

-- ASSUMING Updates table has been updated to have multiple entries
CREATE OR REPLACE FUNCTION check_capacity_before_join() RETURNS TRIGGER AS $$
DECLARE
    room_max_capacity INTEGER := (SELECT U.new_cap FROM Updates U
                                WHERE U.date <= NEW.date
                                AND U.floor = NEW.floor
                                AND U.room = NEW.room
                                ORDER BY U.date DESC
                                LIMIT 1);

    current_capacity INTEGER := (SELECT COUNT(*) FROM Joins J 
                                WHERE NEW.time = J.time
                                AND NEW.date = J.date
                                AND NEW.floor = J.floor
                                AND NEW.room = J.room);
BEGIN
    IF current_capacity < room_max_capacity THEN RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_room_capacity_for_join ON Joins;
CREATE TRIGGER check_room_capacity_for_join
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION check_capacity_before_join();


CREATE OR REPLACE FUNCTION check_if_join_not_in_approves() RETURNS TRIGGER AS $$
DECLARE
    is_not_in boolean := NOT EXISTS (SELECT 1
                        FROM Approves a
                        WHERE NEW.time = a.time AND NEW.date = a.date
                        AND NEW.floor = a.floor AND NEW.room = a.room
                        );
BEGIN
    IF (is_not_in = TRUE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

--check if session is not approved before joining
DROP TRIGGER IF EXISTS check_join_not_approved_session ON Joins;
CREATE TRIGGER check_join_not_approved_session
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION check_if_join_not_in_approves();


CREATE OR REPLACE FUNCTION check_if_in_books() RETURNS TRIGGER AS $$
DECLARE
    is_in boolean := EXISTS (SELECT 1
                        FROM Books b
                        WHERE NEW.time = b.time AND NEW.date = b.date
                        AND NEW.floor = b.floor AND NEW.room = b.room
                        );
BEGIN
    IF (is_in = TRUE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

--check if session is booked before joining
DROP TRIGGER IF EXISTS check_join_booked_session ON Joins;
CREATE TRIGGER check_join_booked_session
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION check_if_in_books();


DROP TRIGGER IF EXISTS employee_joining_not_resigned ON Joins;
CREATE TRIGGER employee_joining_not_resigned
BEFORE INSERT OR UPDATE ON Joins
FOR EACH ROW EXECUTE FUNCTION check_if_resigned();

-- Trigger(s) for leaving meeting; 
-- check that 
-- session has not been approved [Le Zong] [DONE]

CREATE OR REPLACE FUNCTION check_if_leave_not_in_approves() RETURNS TRIGGER AS $$
DECLARE
    is_not_in boolean := NOT EXISTS (SELECT 1
                        FROM Approves a
                        WHERE OLD.time = a.time AND OLD.date = a.date
                        AND OLD.floor = a.floor AND OLD.room = a.room
                        );
BEGIN
    IF (is_not_in = TRUE) THEN RETURN OLD;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- check that session employee is leaving has not been approved. (if approved, no more changes to ppl inside)
DROP TRIGGER IF EXISTS check_leave_not_approved_session ON Joins;
CREATE TRIGGER check_leave_not_approved_session
BEFORE DELETE ON Joins
FOR EACH ROW EXECUTE FUNCTION check_if_leave_not_in_approves();

CREATE OR REPLACE FUNCTION check_if_booker_left() RETURNS TRIGGER AS $$
DECLARE
    -- check if for eid of tuple being deleted from joins, is booker for meeting
    session_booker_id INT := (SELECT B.eid
                              FROM Books B 
                              WHERE B.time = OLD.time
                              AND B.date = OLD.date
                              AND B.floor = OLD.floor
                              AND B.room = OLD.room);
BEGIN
    IF (session_booker_id = OLD.eid) THEN 
        DELETE FROM Books 
        WHERE eid = OLD.eid
        AND time = OLD.time
        AND date = OLD.date
        AND floor = OLD.floor
        AND room = OLD.room;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger checked each time someone leaves a meeting
DROP TRIGGER IF EXISTS booker_leave_meeting ON Joins;
CREATE TRIGGER booker_leave_meeting 
AFTER DELETE ON Joins
FOR EACH ROW EXECUTE FUNCTION check_if_booker_left();


-- Trigger(s) for booking meeting;
-- Check that 
-- booker is still working for company [DONE]
-- person booking is a Booker [Done by Yijie]
-- booker has no fever [Done by Yijie]

DROP TRIGGER IF EXISTS employee_booking_not_resigned ON Books;
CREATE TRIGGER employee_booking_not_resigned
BEFORE INSERT OR UPDATE ON Books
FOR EACH ROW EXECUTE FUNCTION check_if_resigned();

-- Trigger(s) for unbooking meeting; BEFORE DELETE 
-- Check that 
-- employee is still working for company [DONE]: once employee resigned, all meetings
    -- booked by him after resign date are unbooked automatically; trigger on top
-- if approved; remove approval [Yijie] [DONE]
-- if employees joined; removed joined employees [Yijie] [DONE]
-- employee is still working for company [DONE]

CREATE OR REPLACE FUNCTION delete_from_approves() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Approves a 
    WHERE a.time = OLD.time 
    AND a.date = OLD.date
    AND a.floor = OLD.floor
    AND a.room = OLD.room;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_approved_session ON Books;
CREATE TRIGGER delete_approved_session
AFTER DELETE ON Books
FOR EACH ROW EXECUTE FUNCTION delete_from_approves();

-- need to check
CREATE OR REPLACE FUNCTION delete_from_joins() RETURNS TRIGGER AS $$
BEGIN 
    DELETE FROM Joins J
    WHERE J.time = OLD.time 
    AND J.date = OLD.date
    AND J.floor = OLD.floor
    AND J.room = OLD.room;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_joined_session ON Books;
CREATE TRIGGER delete_joined_session
AFTER DELETE ON Books
FOR EACH ROW EXECUTE FUNCTION delete_from_joins();

-- Trigger(s) for approving meetings
-- Check that 
-- person approving is a manager [Le Zong] [already in foreign key]
-- person is still working for company [DONE]
-- session has not been approved [Le Zong] [already in foreign key]
-- session has been booked [Le Zong] [DONE]
-- person approving is in the same department as the meeting room [Le Zong] [DONE]


--check if session being approved is booked
DROP TRIGGER IF EXISTS check_approves_booked_session ON Approves;
CREATE TRIGGER check_approves_booked_session
BEFORE INSERT ON Approves
FOR EACH ROW EXECUTE FUNCTION check_if_in_books();


-- C21
-- Booking approval must be from manager of the dept
CREATE OR REPLACE FUNCTION check_if_approver_same_did() RETURNS TRIGGER AS $$
DECLARE
    is_mgr_of_dept BOOLEAN := is_manager_of_dept(NEW.eid, NEW.floor, NEW.room);
BEGIN
    IF (is_mgr_of_dept = TRUE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

--check if approver is in the same department as the meeting room 
DROP TRIGGER IF EXISTS check_approves_same_did ON Approves;
CREATE TRIGGER check_approves_same_did
BEFORE INSERT ON Approves 
FOR EACH ROW EXECUTE FUNCTION check_if_approver_same_did();


DROP TRIGGER IF EXISTS employee_approving_not_resigned ON Approves;
CREATE TRIGGER employee_approving_not_resigned
BEFORE INSERT OR UPDATE ON Approves
FOR EACH ROW EXECUTE FUNCTION check_if_resigned();

/**
 * NON-PROCEDURE RELATED CONSTRAINTS
 */


-- Refactor internal checks for reuse
-- STORED FUNCTION TO CHECK IF JUNIOR
CREATE OR REPLACE FUNCTION is_junior(checked_eid INTEGER) 
RETURNS BOOLEAN AS $$
DECLARE
    is_in BOOLEAN;
BEGIN
    is_in := EXISTS (SELECT 1 FROM Juniors J WHERE checked_eid = J.eid);
    RETURN is_in;
END;
$$ LANGUAGE plpgsql;

-- STORED FUNCTION TO CHECK IF SENIOR
CREATE OR REPLACE FUNCTION is_senior(checked_eid INTEGER)
RETURNS BOOLEAN AS $$
DECLARE 
    is_in BOOLEAN;
BEGIN
    is_in := EXISTS (SELECT 1 FROM Seniors S WHERE checked_eid = S.eid);
    RETURN is_in;
END;
$$ LANGUAGE plpgsql;

-- STORED FUNCTION TO CHECK IF MANAGER
CREATE OR REPLACE FUNCTION is_manager(checked_eid INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    is_in BOOLEAN;
BEGIN
    is_in := EXISTS (SELECT 1 FROM Managers M WHERE checked_eid = M.eid);
    RETURN is_in;
END;
$$ LANGUAGE plpgsql;

-- STORED FUNCTION TO CHECK IF BOOKER
CREATE OR REPLACE FUNCTION is_booker(checked_eid INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    is_in BOOLEAN;
BEGIN
    is_in := EXISTS (SELECT 1 FROM Bookers B WHERE checked_eid = B.eid);
    RETURN is_in;
END;
$$ LANGUAGE plpgsql;

-- STORED FUNCTION TO CHECK IF MANAGER OF THAT DEPT
CREATE OR REPLACE FUNCTION is_manager_of_dept(checked_eid INTEGER, checked_floor INTEGER, checked_room INTEGER)
RETURNS BOOLEAN AS $$
DECLARE 
    is_mgr_of_dept BOOLEAN;
BEGIN
    is_mgr_of_dept := EXISTS (SELECT 1
                        FROM LocatedIn l
                        JOIN WorksIn w
                        ON l.floor = checked_floor
                        AND l.room = checked_room
                        AND l.did = w.did
                        WHERE checked_eid = w.eid);
    RETURN is_mgr_of_dept;
END;
$$ LANGUAGE plpgsql;


-- C12
-- insert into seniors is not junior or manager
CREATE OR REPLACE FUNCTION check_if_jr_or_mgr() RETURNS TRIGGER AS $$
DECLARE
    is_in_jr BOOLEAN := is_junior(NEW.eid);
    is_in_mgr BOOLEAN := is_manager(NEW.eid);
BEGIN
    IF (is_in_jr = FALSE AND is_in_mgr = FALSE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS senior_employee_not_jr_or_mgr ON Seniors;
CREATE TRIGGER senior_employee_not_jr_or_mgr
BEFORE INSERT ON Seniors
FOR EACH ROW EXECUTE FUNCTION check_if_jr_or_mgr();


-- C12
-- insert into juniors is not senior or manager
CREATE OR REPLACE FUNCTION check_if_sr_or_mgr() RETURNS TRIGGER AS $$
DECLARE
    is_in_sr BOOLEAN := is_senior(NEW.eid);
    is_in_mgr BOOLEAN := is_manager(NEW.eid);
BEGIN
    IF (is_in_sr = FALSE AND is_in_mgr = FALSE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS junior_employee_not_booker ON Juniors;
CREATE TRIGGER junior_employee_not_booker
BEFORE INSERT ON Juniors
FOR EACH ROW EXECUTE FUNCTION check_if_sr_or_mgr();


-- C12
-- insert into manager is not senior or junior
CREATE OR REPLACE FUNCTION check_if_sr_or_jr() RETURNS TRIGGER AS $$
DECLARE
    is_in_jr BOOLEAN := is_junior(NEW.eid);
    is_in_sr BOOLEAN := is_senior(NEW.eid);
BEGIN
    IF (is_in_jr = FALSE AND is_in_sr = FALSE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS manager_not_sr_or_jr ON Managers;
CREATE TRIGGER manager_not_sr_or_jr
BEFORE INSERT ON Managers
FOR EACH ROW EXECUTE FUNCTION check_if_sr_or_jr();


-- C13, C14
-- Only allow inserts for seniors or managers for Books table
CREATE OR REPLACE FUNCTION check_if_can_book() RETURNS TRIGGER AS $$
DECLARE
    is_in_booker BOOLEAN := is_booker(NEW.eid);
BEGIN
    IF (is_in_booker = TRUE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS valid_room_booker ON Books;
CREATE TRIGGER valid_room_booker
BEFORE INSERT ON Books
FOR EACH ROW EXECUTE FUNCTION check_if_can_book();
-- insert into Sessions values ('11:00:00', '2022-10-17', 5, 5);
-- insert into Books (eid, time, date, floor, room) values (293, '11:00:00', '2022-10-16', 1, 1);



-- C24
-- updates trigger to check if is manager and dept of manager+room for updating capacity
CREATE OR REPLACE FUNCTION check_if_mgr_of_dept() RETURNS TRIGGER AS $$
DECLARE
    is_in_mgr BOOLEAN := is_manager(NEW.eid);
    is_mgr_of_dept BOOLEAN := is_manager_of_dept(NEW.eid, NEW.floor, NEW.room);
BEGIN
    IF (is_in_mgr = TRUE AND is_mgr_of_dept = TRUE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- C24
DROP TRIGGER IF EXISTS check_valid_employee_update ON Updates;
CREATE TRIGGER check_valid_employee_update
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_if_mgr_of_dept();

-- Due to the pandemic, we have to be vigilant. If an employee is recorded to have a fever at a given day D, a few things
-- must happen:
-- 1. The employee is removed from all future meeting room booking, approved or not. [DONE]
-- If the employee is the one booking the room, the booking is cancelled, approved or not. [DONE]
-- This employee cannot book a room until they are no longer having fever. [DONE]
-- 2. All employees in the same approved meeting room from the past 3 (i.e., from day D-3 to day D) days are contacted. [NOT SURE WHAT THEY MEAN BY CONTACTED]
-- These employees are removed from future meeting in the next 7 days (i.e., from day D to day D+7). [DONE, BUT ONLY FOR JOINS. PROBABLY NEED SOME ON DELETE CASCADE FOR BOOKS]
-- We say that these employees were in close contact with the employee having a fever.
-- These restrictions are based on the assumptions that once approved, the meeting will occur with all participants
-- attending.

CREATE OR REPLACE FUNCTION remove_on_fever() RETURNS TRIGGER AS $$
DECLARE
    has_fever BOOLEAN := (NEW.temp > 37.5);
    curs CURSOR FOR (SELECT b.time, b.date, b.floor, b.room FROM
            Books b WHERE NEW.eid = b.eid 
            AND b.date > NEW.date);
    r1 RECORD;
BEGIN
    IF (has_fever) THEN

        -- meetings employee joins
        DELETE FROM Joins j 
        WHERE j.eid = NEW.eid
        AND j.date >= NEW.date;

        -- meetings employee has booked
        DELETE FROM Books b 
        WHERE b.eid = NEW.eid
        AND b.date >= NEW.date;

    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS remove_on_fever ON HealthDeclaration;
CREATE TRIGGER remove_on_fever
AFTER INSERT OR UPDATE ON HealthDeclaration
FOR EACH ROW EXECUTE FUNCTION remove_on_fever();

CREATE OR REPLACE FUNCTION check_for_fever() RETURNS TRIGGER AS $$
DECLARE
    has_fever BOOLEAN := ((SELECT temp
                        FROM HealthDeclaration WHERE eid = NEW.eid
                        ORDER BY date DESC
                        LIMIT 1) > 37.5);
BEGIN
    IF (has_fever) THEN RETURN NULL;
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_for_fever ON Books;
CREATE TRIGGER check_for_fever
BEFORE INSERT ON Books
FOR EACH ROW EXECUTE FUNCTION check_for_fever();

-- C19
-- Prevent any fever employees from joining
DROP TRIGGER IF EXISTS check_for_fever_join ON Joins;
CREATE TRIGGER check_for_fever_join
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION check_for_fever();

CREATE OR REPLACE FUNCTION remove_contacted_employees_on_fever() RETURNS TRIGGER AS $$
DECLARE
    has_fever BOOLEAN := (NEW.temp > 37.5);
    -- getting all employees that joined/booked rooms that this employee joined/booked in the past 3 days
    curs CURSOR FOR (SELECT j1.eid FROM
            Joins j1 JOIN Joins j2
            ON j2.eid = NEW.eid
            AND j2.date < NEW.date
            AND j2.date >= NEW.date - 3
            AND j2.time = j1.time
            AND j2.date = j1.date
            AND j2.floor = j1.floor
            AND j2.room = j1.room
            JOIN Approves a
            ON j2.date = a.date
            AND j2.time = a.time
            AND j2.floor = a.floor
            AND j2.room = a.room);
    r1 RECORD;
    
BEGIN
    IF (has_fever) THEN

        -- remove all employees that attended meetings booked by this employee in the past 3 days
        -- from meetings in the next 7 days (Both joining and bookings)
        OPEN curs;
        LOOP
            FETCH curs INTO r1;
            EXIT WHEN NOT FOUND;
            DELETE FROM Joins j1
            WHERE r1.eid = j1.eid
            AND j1.date >= NEW.date
            AND j1.date <= NEW.date + 7;
        END LOOP;
        CLOSE curs;

    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS remove_on_fever ON HealthDeclaration;
CREATE TRIGGER remove_on_fever
AFTER INSERT OR UPDATE ON HealthDeclaration
FOR EACH ROW EXECUTE FUNCTION remove_on_fever();

DROP TRIGGER IF EXISTS remove_contacted_employees_on_fever ON HealthDeclaration;
CREATE TRIGGER remove_contacted_employees_on_fever
AFTER INSERT OR UPDATE ON HealthDeclaration
FOR EACH ROW EXECUTE FUNCTION remove_contacted_employees_on_fever();

-- BASIC
-- add_department
CREATE OR REPLACE PROCEDURE add_department 
    (did INTEGER, dname TEXT)
AS $$
    INSERT INTO Departments (did, dname) VALUES (did, dname);

$$ LANGUAGE sql;

--remove_department
CREATE OR REPLACE PROCEDURE remove_department
    (input_did INTEGER)
AS $$
DECLARE
    num_of_employees_in_dept INTEGER := (SELECT COUNT(*) FROM WorksIn WHERE did = input_did);
    num_of_employees_resigned_in_dept INTEGER := (SELECT COUNT(*) FROM WorksIn W
                                                    NATURAL JOIN Employees E
                                                    WHERE W.did = input_did
                                                    AND E.resign_date IS NOT NULL);
    num_of_rooms_in_dept INTEGER := (SELECT COUNT(*) FROM LocatedIn WHERE did = input_did);
BEGIN
    IF ((num_of_employees_in_dept = 0 
        OR num_of_employees_in_dept = num_of_employees_resigned_in_dept)
        AND num_of_rooms_in_dept = 0) THEN
        DELETE FROM Departments d
        WHERE input_did = d.did;
    END IF;
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
    isClash boolean := EXISTS(SELECT 1
            FROM Joins j
            WHERE j.eid = booker_eid
            AND j.time >= start_hour
            AND j.time < end_hour
            AND j.date = book_date);  

    tempTime TIME := start_hour;
    currTime TIME := start_hour;
BEGIN
    -- if numSessions enough; adding numSessions of 1 hr increments
    -- will be equal to end_hour; numSessions <= necessary; never over
    FOR count in 1..numSessions LOOP
        tempTime := tempTime + '01:00:00'; 
    END LOOP;
    -- if tempTime = end_hour; add all that can be added
    IF (tempTime = end_hour AND NOT isClash) THEN
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
CREATE OR REPLACE FUNCTION contact_tracing(employee_id INTEGER) RETURNS TABLE (employee_id2 INTEGER) AS $$
DECLARE
    has_fever BOOLEAN := ((SELECT temp
                        FROM HealthDeclaration WHERE eid = employee_id
                        ORDER BY date DESC
                        LIMIT 1) > 37.5);
    fever_date DATE := ((SELECT date
                        FROM HealthDeclaration WHERE eid = employee_id AND temp > 37.5
                        ORDER BY date DESC
                        LIMIT 1));
BEGIN
    IF (has_fever) THEN
        RETURN QUERY
            SELECT j1.eid FROM
            Joins j1 JOIN Joins j2
            ON j2.eid = employee_id
            AND j1.eid <> employee_id
            AND j2.date < fever_date
            AND j2.date >= fever_date - 3
            AND j2.time = j1.time
            AND j2.date = j1.date
            AND j2.floor = j1.floor
            AND j2.room = j1.room
            JOIN Approves a
            ON j2.date = a.date
            AND j2.time = a.time
            AND j2.floor = a.floor
            AND j2.room = a.room;
        ELSE
            RETURN;
        END IF;
END;
$$ LANGUAGE plpgsql;


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
