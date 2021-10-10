CREATE TABLE Employees (
    eid INTEGER,
    ename TEXT,
    email TEXT UNIQUE,
    resign_date DATE,
    home_number INTEGER,
    mobile_number INTEGER,
    office_number INTEGER,
    PRIMARY KEY (eid)
);

CREATE TABLE WorksIn (
    eid INTEGER, 
    did INTEGER, 
    PRIMARY KEY (eid, did),
    FOREIGN KEY (eid) REFERENCES Employees,
    FOREIGN KEY (did) REFERENCES Departments
);

CREATE TABLE Departments (
    did INTEGER,
    dname TEXT,
    PRIMARY KEY (did)
);

CREATE TABLE MeetingRooms (
    room INTEGER,
    floor INTEGER,
    rname TEXT,
    PRIMARY KEY (room, floor)
);

CREATE TABLE LocatedIn (
    room INTEGER,
    floor INTEGER,
    did INTEGER NOT NULL,
    PRIMARY KEY (room, floor) REFERENCES MeetingRooms,
    FOREIGN KEY (did) REFERENCES Departments
);

CREATE TABLE Juniors (
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Employees
);

CREATE TABLE Bookers (
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Employees
);

CREATE TABLE Seniors (
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Bookers
);

CREATE TABLE Managers (
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Bookers
);

CREATE TABLE Updates (
    eid INTEGER,
    date DATE,
    new_cap INTEGER,
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (eid, date, room, floor),
    FOREIGN KEY (eid) REFERENCES Managers,
    FOREIGN KEY (room, floor) REFERENCES MeetingRooms
);

CREATE TABLE HealthDeclaration (
    date DATE,
    temp NUMERIC,
    eid INTEGER,
    PRIMARY KEY (eid, date),
    FOREIGN KEY (eid) REFERENCES Employees
);

CREATE TABLE Sessions (
    time TIME,
    date DATE,
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (time, date, room, floor)
);

CREATE TABLE Joins (
    eid INTEGER,
    time TIME,
    date DATE,
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (eid, time, date, room, floor),
    FOREIGN KEY (eid) REFERENCES Employees,
    FOREIGN KEY (time, date, room, floor) REFERENCES Sessions
);

CREATE TABLE Books (
    eid INTEGER,
    time TIME,
    date DATE,
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (eid, time, date, room, floor),
    FOREIGN KEY (eid) REFERENCES Bookers,
    FOREIGN KEY (time, date, room, floor) REFERENCES Sessions
)

CREATE TABLE Approves (
    eid INTEGER,
    time TIME,
    date DATE,
    room INTEGER,
    floor INTEGER,
    PRIMARY KEY (eid, time, date, room, floor),
    FOREIGN KEY (eid) REFERENCES Managers,
    FOREIGN KEY (time, date, room, floor) REFERENCES Sessions
)
