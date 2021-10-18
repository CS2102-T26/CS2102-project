-- BASIC
-- change capacity
-- eid added as only manager can change capacity of the room for that date
CREATE OR REPLACE PROCEDURE change_capacity(
    IN manager_id INT, IN floor_number INT, IN room_number INT, IN capacity INT, IN new_date DATE
) AS $$ 
    UPDATE Updates SET new_cap = capacity,  date = new_date 
    WHERE room = room_number 
    AND floor = floor_number
    AND eid = manager_id
    ;
$$ LANGUAGE sql;

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

-- Test
CALL add_employee('Swann Tet Aung', '123-456-7890', '345-678-9012', '789-012-3456', 'Junior', 9);
CALL add_employee('Marcus Bory Ong', '456-123-7890', '901-345-6782', '012-349-7568', 'Senior', 10);

-- remove_employee
-- use trigger to delete from all bookings if senior or manager
-- delete all approved meetings if manager
-- Remove from all joined meetings in the future FOR ALL
CREATE OR REPLACE PROCEDURE remove_employee(
    IN e_id INT, IN last_date DATE
) AS $$
    

$$ LANGUAGE sql;

-- CORE
-- search_room

-- book_room

-- unbook_room