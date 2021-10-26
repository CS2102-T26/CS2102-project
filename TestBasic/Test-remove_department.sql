-- EXPECTED PASS (no rooms no employees)
CALL add_department(15, 'TEST');
CALL remove_department(15);

-- EXPECTED PASS (no rooms, all resigned)
CALL add_department(16, 'TEST2');
CALL add_employee('RESIGNER', '5081738778', '927730053912', '8295420783
', 'Junior', '16');
CALL remove_employee(310, current_date - 1);
CALL remove_department(16); -- should pass since employee resigned

-- EXPECTED FAIL (got rooms, but all resigned)
CALL add_department(17, 'TEST3');
CALL add_employee('CS-man', '5081738778', '927753912', '8295420783
', 'Manager', '17');
CALL add_room(17, 1, 'Room 17-1', 10, 311, 17, null);
CALL remove_employee(311, current_date - 1);
CALL remove_department(17); -- should fail

-- EXPECTED FAIL (these departments have active employees)
CALL remove_department(8);
CALL remove_department(9);

-- TEST 
SELECT * FROM Departments;