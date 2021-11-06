DROP TABLE IF EXISTS Employees, WorksIn, Departments, MeetingRooms, LocatedIn, Juniors, 
Bookers, Seniors, Managers, Updates, HealthDeclaration, Sessions, Joins, Books, Approves CASCADE;

DROP FUNCTION IF EXISTS 
remove_bookings_over_capacity(), 
remove_from_future_records(), 
check_if_resigned(), 
check_time_clash_before_join(),
check_capacity_before_join(), 
check_if_join_not_in_approves(), 
check_if_in_books(), 
check_if_leave_not_in_approves(), 
check_if_booker_left(),
delete_from_approves(), 
delete_from_joins(), 
check_if_approver_same_did(), 
is_junior(checked_eid INTEGER), 
is_senior(checked_eid INTEGER), 
is_manager(checked_eid INTEGER), 
is_booker(checked_eid INTEGER), 
is_manager_of_dept(checked_eid INTEGER, checked_floor INTEGER, checked_room INTEGER),
check_if_jr_or_mgr(), 
check_if_sr_or_mgr(), 
check_if_sr_or_jr(), 
check_if_can_book(), 
check_if_mgr_of_dept(), 
remove_on_fever(), 
check_for_fever(),
remove_contacted_employees_on_fever(), 
search_room(IN search_capacity INT, IN search_date DATE, IN start_hour TIME, IN end_hour TIME), 
contact_tracing(employee_id INTEGER), 
non_compliance(IN start_date DATE, IN end_date DATE), 
view_booking_report(IN start_date DATE, IN input_eid INTEGER), 
view_future_meeting(IN start_date DATE, IN input_eid INTEGER), 
view_manager_report(IN start_date DATE, IN input_eid INTEGER) 
CASCADE;

DROP PROCEDURE IF EXISTS 
add_department(did INTEGER, dname TEXT), 
remove_department(input_did INTEGER), 
add_room(floor INTEGER, room INTEGER, rname TEXT, new_cap INTEGER, eid INTEGER, did INTEGER, date DATE), 
change_capacity(IN manager_id INT, IN floor_number INT, IN room_number INT, IN capacity INT, IN new_date DATE), 
add_employee(IN e_name TEXT, IN e_home_number VARCHAR(15), IN e_mobile_number VARCHAR(15),
    IN e_office_number VARCHAR(15), IN e_type TEXT, IN e_did INT), 
remove_employee(IN e_id INT, IN last_date DATE), 
book_room(IN floor_number INT, IN room_number INT, IN book_date DATE, 
    IN start_hour TIME, IN end_hour TIME, IN booker_eid INT),
unbook_room(IN floor_number INT, IN room_number INT, IN book_date DATE,
    IN start_hour TIME, IN end_hour TIME, IN unbooker_eid INT), 
join_meeting(floor_number INTEGER, room_number INTEGER, join_date DATE, 
    start_time TIME, end_time TIME, joiner_eid INTEGER), 
leave_meeting(floor INTEGER, room INTEGER, date DATE, start_time TIME, end_time TIME, eid INTEGER), 
approve_meeting(floor INTEGER, room INTEGER, date DATE, start_time TIME, end_time TIME, eid INTEGER), 
declare_health(employee_id INTEGER, declared_date DATE, declared_temperature NUMERIC) 
CASCADE;

CREATE TABLE Employees (
    eid SERIAL, -- to get auto increment
    ename TEXT,
    email TEXT UNIQUE NOT NULL, -- c2, c3
    resign_date DATE, -- c3 (date is NULL if active), c33 use soft delete
    home_number VARCHAR(15),
    mobile_number VARCHAR(15) UNIQUE,
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
    FOREIGN KEY (did) REFERENCES Departments ON DELETE CASCADE-- c9
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
    FOREIGN KEY (did) REFERENCES Departments ON DELETE CASCADE-- c11
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
    new_cap INTEGER NOT NULL,
    floor INTEGER,
    room INTEGER,
    PRIMARY KEY (date, floor, room),
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
    PRIMARY KEY (time, date, floor, room),
    FOREIGN KEY (floor, room) REFERENCES MeetingRooms (floor, room) ON DELETE CASCADE
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
    -- c16 need trigger to check health declaration for fever
    -- c34 need trigger to check if employee is still active worker
    eid INTEGER,
    time TIME,
    date DATE,
    floor INTEGER,
    room INTEGER,
    PRIMARY KEY (time, date, floor, room), -- c15 remove eid from pkey for prevent different people from booking
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

