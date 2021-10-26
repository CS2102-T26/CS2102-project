-- EXPECTED PASS (correct manager id)
CALL change_capacity(306, 7, 1, 12, CURRENT_DATE);
CALL change_capacity(309, 8, 1, 12, CURRENT_DATE);
SELECT * FROM Updates;

-- EXPECTED PASS (update same day)
CALL change_capacity(306, 7, 1, 15, CURRENT_DATE);
CALL change_capacity(309, 8, 1, 15, CURRENT_DATE);
SELECT * FROM Updates;

-- EXPECTED FAIL (manager change another dept id)
CALL change_capacity(306, 8, 1, 10, CURRENT_DATE);

-- EXPECTED FAIL (non-manager change SAME dept id)
CALL change_capacity(301, 7, 2, 20, CURRENT_DATE);
