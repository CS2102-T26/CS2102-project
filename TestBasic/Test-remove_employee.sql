-- EXPECTED PASS
CALL remove_employee(301, CURRENT_DATE); -- today
CALL remove_employee(306, '2021-10-10'); -- past
CALL remove_employee(308, '2022-10-10'); -- future
SELECT * FROM Employees WHERE eid > 300;

-- EXPECTED FAIL, no more such employee
CALL remove_employee(301, CURRENT_DATE);