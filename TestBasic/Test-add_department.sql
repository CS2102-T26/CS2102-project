-- EXPECTED PASS
-- New did, new dname
CALL add_department(13, 'External Relations');

-- EXPECTED PASS
-- New did, existing name
CALL add_department(14, 'Engineering');

-- EXPECTED FAIL
-- Old did, new name
CALL add_department(14, 'Internal Relations');

-- EXPECTED FAIL
-- Old did, old name
CALL add_department(14, 'External Relations');

-- EXPECTED FAIL
-- New did, no name
CALL add_department(15, NULL);