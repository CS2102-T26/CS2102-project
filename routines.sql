-- insert into departments values (1, 'HR'), (2, 'LOGS'), (3, 'HR'), (4, 'ADMIN');
-- insert into departments values (1, 'HR'), (2, 'LOGS'), (3, 'HR'), (4, 'ADMIN');


-- psql -d cs2102_tp -U postgres -f C:\Users\lezon\cs2102_tp\CS2102-project/schema.sql
-- DROP VIEW fever;
-- DROP TABLE WorksIn, MeetingRooms, LocatedIn, Employees, Departments, Juniors, Bookers, Seniors, Managers, Updates, HealthDeclaration, Sessions, Joins, Books, Approves;
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
-- call add_room(11,1,'Store', 5, null,null);


--CORE join_meeting
-- no end_time 
CREATE OR REPLACE PROCEDURE join_meeting
    (floor INTEGER, room INTEGER, date DATE, start_time TIME, eid INTEGER)
AS $$
    INSERT INTO Joins (eid, time, date, floor, room)
    VALUES (eid, start_time, date, floor, room)
$$ LANGUAGE sql;

