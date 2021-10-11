-- insert into departments values (1, 'HR'), (2, 'LOGS'), (3, 'HR'), (4, 'ADMIN');
-- psql -d cs2102_tp -U postgres -f C:\Users\lezon\cs2102_tp\CS2102-project/schema.sql


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
    (floor INTEGER, room INTEGER, rname TEXT, capacity INTEGER)
AS $$
    INSERT INTO MeetingRooms (floor, room, rname)
    VALUES (floor, room, rname);

    INSERT INTO Updates (eid, date, new_cap, floor, room)
    VALUES (null, null, capacity, floor, room);

$$ LANGUAGE sql;