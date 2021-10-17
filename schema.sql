CREATE TABLE Employees (
    eid INTEGER,
    ename TEXT,
    email TEXT UNIQUE NOT NULL, -- c2, c3
    resign_date DATE, -- c3 (date is NULL if active), c33 use soft delete
    home_number VARCHAR(15),
    mobile_number VARCHAR(15),
    office_number VARCHAR(15),
    PRIMARY KEY (eid) -- c1
);

CREATE TABLE WorksIn (
    eid INTEGER, 
    did INTEGER NOT NULL, -- c8 
    PRIMARY KEY (eid), 
    FOREIGN KEY (eid) REFERENCES Employees,
    FOREIGN KEY (did) REFERENCES Departments -- c9
);

CREATE TABLE Departments (
    did INTEGER,
    dname TEXT NOT NULL, -- c5
    PRIMARY KEY (did) -- c4
);

CREATE TABLE MeetingRooms (
    room INTEGER,
    floor INTEGER,
    rname TEXT NOT NULL, -- c7
    PRIMARY KEY (room, floor) -- c6
);

CREATE TABLE LocatedIn (
    room INTEGER,
    floor INTEGER,
    did INTEGER NOT NULL,
    PRIMARY KEY (room, floor), -- c10, each room, floor can only belong to one did
    FOREIGN KEY(room, floor) REFERENCES MeetingRooms,
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
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (eid, date, room, floor),
    FOREIGN KEY (eid) REFERENCES Managers,
    FOREIGN KEY (room, floor) REFERENCES MeetingRooms
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
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (time, date, room, floor)
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
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (eid, time, date, room, floor),
    FOREIGN KEY (eid) REFERENCES Employees,
    FOREIGN KEY (time, date, room, floor) REFERENCES Sessions,
    CHECK (date > CURRENT_DATE AND time > CURRENT_TIME) -- c26 need verify syntax from psql docs
);

CREATE TABLE Books ( -- c13, c14 need trigger to check if booker is junior, senior, manager
    -- c15 need trigger to check if booking for candidate room exists already for booked hour
    -- c16 need trigger to check health declaration for fever
    -- c34 need trigger to check if employee is still active worker
    eid INTEGER,
    time TIME,
    date DATE,
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (eid, time, date, room, floor),
    FOREIGN KEY (eid) REFERENCES Bookers,
    FOREIGN KEY (time, date, room, floor) REFERENCES Sessions,
    CHECK (date > CURRENT_DATE AND time > CURRENT_TIME) -- c25 need verify syntax
);

CREATE TABLE Approves ( 
    -- c20 need check for manager eid
    -- c21 need check for manager dept and meeting room dept
    -- c34 need trigger to check if employee is still active worker
    eid INTEGER NOT NULL, -- c22 add not null constraint
    time TIME,
    date DATE,
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (time, date, room, floor), -- c22 remove eid so meeting only approved once
    FOREIGN KEY (eid) REFERENCES Managers,
    FOREIGN KEY (time, date, room, floor) REFERENCES Sessions,
    CHECK (date > CURRENT_DATE AND time > CURRENT_TIME) -- c27 need verify syntax
);

-- NEED TO DO CONTACT TRACING LATER