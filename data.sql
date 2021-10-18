CREATE TABLE Employees (
    eid INTEGER,
    ename TEXT,
    email TEXT UNIQUE NOT NULL, -- c2, c3
    resign_date DATE, -- c3 (date is NULL if active), c33 use soft delete
    home_number INTEGER,
    mobile_number INTEGER,
    office_number INTEGER,
    PRIMARY KEY (eid) -- c1
);

INSERT INTO Employees VALUES (0, 'admin', 'admin', null, null, null, null);
INSERT INTO Bookers VALUES (0);
INSERT INTO Managers VALUES (0);


CREATE TABLE Managers ( -- c12, need trigger to ensure inserted employee is not senior or junior
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Bookers
);

CREATE TABLE MeetingRooms (
    floor INTEGER,
    room INTEGER,
    rname TEXT NOT NULL, -- c7
    capacity INTEGER,
    PRIMARY KEY (floor, room) -- c6
);