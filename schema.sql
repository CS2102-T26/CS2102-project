DROP TABLE IF EXISTS Employees, WorksIn, Departments, MeetingRooms, LocatedIn, Juniors, 
Bookers, Seniors, Managers, Updates, HealthDeclaration, Sessions, Joins, Books, Approves CASCADE;

CREATE TABLE Employees (
    eid SERIAL, -- to get auto increment
    ename TEXT,
    email TEXT UNIQUE NOT NULL, -- c2, c3
    resign_date DATE, -- c3 (date is NULL if active), c33 use soft delete
    home_number VARCHAR(15),
    mobile_number VARCHAR(15),
    office_number VARCHAR(15),
    PRIMARY KEY (eid) -- c1
);

CREATE TABLE Departments (
    did INTEGER,
    dname TEXT NOT NULL, -- c5
    PRIMARY KEY (did) -- c4
);

CREATE TABLE WorksIn (
    eid INTEGER, 
    did INTEGER NOT NULL, -- c8 
    PRIMARY KEY (eid), 
    FOREIGN KEY (eid) REFERENCES Employees,
    FOREIGN KEY (did) REFERENCES Departments -- c9
);

CREATE TABLE MeetingRooms (
    floor INTEGER,
    room INTEGER,
    rname TEXT NOT NULL, -- c7
    -- capacity INTEGER,
    PRIMARY KEY (floor, room) -- c6
);

CREATE TABLE LocatedIn (
    floor INTEGER,
    room INTEGER,
    did INTEGER NOT NULL,
    PRIMARY KEY (floor, room), -- c10, each room, floor can only belong to one did
    FOREIGN KEY(floor, room) REFERENCES MeetingRooms,
    FOREIGN KEY (did) REFERENCES Departments -- c11
);

CREATE TABLE Juniors ( -- c12, need trigger to ensure inserted employee is not booker
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Employees
);

CREATE TABLE Bookers (
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Employees
);

CREATE TABLE Seniors ( -- c12, need trigger to ensure inserted employee is not junior or manager
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Bookers
);

CREATE TABLE Managers ( -- c12, need trigger to ensure inserted employee is not senior or junior
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Bookers
);

CREATE TABLE Updates (
    -- c24 need trigger to check if is manager and dept of manager+room
    eid INTEGER,
    date DATE,
    new_cap INTEGER,
    floor INTEGER,
    room INTEGER,
    PRIMARY KEY (eid, date, floor, room),
    FOREIGN KEY (eid) REFERENCES Managers,
    FOREIGN KEY (floor, room) REFERENCES MeetingRooms DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE HealthDeclaration ( -- c28 cant really enforce
    date DATE,
    temp NUMERIC NOT NULL, -- c29
    eid INTEGER,
    PRIMARY KEY (eid, date), -- c30
    CHECK (temp >= 34.0 AND temp <= 43.0), -- c32
    FOREIGN KEY (eid) REFERENCES Employees
);

CREATE OR REPLACE VIEW fever AS (
    SELECT * 
    FROM HealthDeclaration
    WHERE temp > 37.5
);

CREATE TABLE Sessions (
    time TIME,
    date DATE,
    floor INTEGER,
    room INTEGER,
    PRIMARY KEY (time, date, floor, room)
);

CREATE TABLE Joins (
    -- c17 need trigger to check if a meeting is scheduled/booked in the room at that time
    -- c18 need trigger/procedure to join room to join booker
    -- c19 need trigger to check health declaration for fever
    -- c23 need trigger to check if approves before allowing insert into joins
    -- c34 need trigger to check if employee is still active worker
    eid INTEGER,
    time TIME,
    date DATE,
    floor INTEGER,
    room INTEGER,
    PRIMARY KEY (eid, time, date, floor, room),
    FOREIGN KEY (eid) REFERENCES Employees,
    FOREIGN KEY (time, date, floor, room) REFERENCES Sessions,
    CHECK (date > CURRENT_DATE OR (date = CURRENT_DATE AND time > CURRENT_TIME)) -- c26 need verify syntax from psql docs
);

CREATE TABLE Books ( -- c13, c14 need trigger to check if booker is junior, senior, manager
    -- c15 need trigger to check if booking for candidate room exists already for booked hour
    -- c16 need trigger to check health declaration for fever
    -- c34 need trigger to check if employee is still active worker
    eid INTEGER,
    time TIME,
    date DATE,
    floor INTEGER,
    room INTEGER,
    PRIMARY KEY (eid, time, date, floor, room),
    FOREIGN KEY (eid) REFERENCES Bookers,
    FOREIGN KEY (time, date, floor, room) REFERENCES Sessions,
    CHECK (date > CURRENT_DATE OR (date = CURRENT_DATE AND time > CURRENT_TIME)) -- c25 need verify syntax
);

CREATE TABLE Approves ( 
    -- c20 need check for manager eid
    -- c21 need check for manager dept and meeting room dept
    -- c34 need trigger to check if employee is still active worker
    eid INTEGER NOT NULL, -- c22 add not null constraint
    time TIME,
    date DATE,
    floor INTEGER,
    room INTEGER,
    PRIMARY KEY (time, date, floor, room), -- c22 remove eid so meeting only approved once
    FOREIGN KEY (eid) REFERENCES Managers,
    FOREIGN KEY (time, date, floor, room) REFERENCES Sessions,
    CHECK (date > CURRENT_DATE OR (date = CURRENT_DATE AND time > CURRENT_TIME)) -- c27 need verify syntax
);

-- NEED TO DO CONTACT TRACING LATER

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
-- session has not been approved [DONE]
-- not over room capacity [Le Zong claims he can do]

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
