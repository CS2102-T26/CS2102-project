-- Triggers

-- Trigger function removing any room booking after capacity update date
-- with number of employees over the new capacity
CREATE OR REPLACE FUNCTION remove_bookings_over_capacity() RETURNS TRIGGER AS $$
DECLARE
    -- Selects all booked meetings with capacity over new_capacity 
    -- for room where capacity was changed
    curs CURSOR FOR (SELECT B.time, B.date, B.floor, B.room, COUNT(J.eid)
                    FROM Books B JOIN Joins J 
                        ON B.time = J.time AND B.date = J.date
                           AND B.floor = J.floor AND B.room = J.room
                    WHERE B.floor = NEW.floor AND B.room = NEW.room and B.date > NEW.new_cap
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

-- Trigger to remove all sessions not meeting requirements after cap update
DROP TRIGGER IF EXISTS capacity_updated ON Updates;
CREATE TRIGGER capacity_updated
AFTER UPDATE ON Updates
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

CREATE OR REPLACE FUNCTION check_if_in_approves() RETURNS TRIGGER AS $$
DECLARE
    is_in boolean := NOT EXISTS (SELECT 1
                        FROM Approves a
                        WHERE NEW.time = a.time AND NEW.date = a.date
                        AND NEW.floor = a.floor AND NEW.room = a.room
                        );
BEGIN
    IF (is_in = TRUE) THEN RETURN NEW;
    ELSE RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

--check if session is not approved before joining
DROP TRIGGER IF EXISTS check_join_not_approved_session ON Joins;
CREATE TRIGGER check_join_not_approved_session
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION check_if_in_approves();


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

-- Trigger(s) for booking meeting;
-- Check that 
-- booker is still working for company [DONE]
-- person booking is a Booker [Swann]
-- booker has no fever [Swann]

DROP TRIGGER IF EXISTS employee_booking_not_resigned ON Books;
CREATE TRIGGER employee_booking_not_resigned
BEFORE INSERT OR UPDATE ON Books
FOR EACH ROW EXECUTE FUNCTION check_if_resigned();

-- Trigger(s) for unbooking meeting; BEFORE DELETE 
-- Check that 
-- employee is still working for company [DONE]: once employee resigned, all meetings
    -- booked by him after resign date are unbooked automatically; trigger on top
-- if approved; remove approval [Swann]
-- if employees joined; removed joined employees [Swann]
-- employee is still working for company [DONE]

-- Trigger(s) for approving meetings
-- Check that 
-- person approving is a manager
-- person is still working for company [DONE]
-- session has not past 
-- session has not been approved
-- session has been booked
-- person approving is in the same department as the meeting room

DROP TRIGGER IF EXISTS employee_approving_not_resigned ON Approves;
CREATE TRIGGER employee_approving_not_resigned
BEFORE INSERT OR UPDATE ON Approves
FOR EACH ROW EXECUTE FUNCTION check_if_resigned();

-- Trigger(s) for leaving meeting; 
-- check that 
-- session has not been approved
-- eid is in meeting initially
