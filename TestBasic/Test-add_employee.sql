-- EXPECTED PASS
-- Correct inputs
CALL add_employee('Vanilla', '5081738778', '9277300539', '8295420783
', 'Junior', '13');

-- EXPECTED PASS
-- NULL contact numbers
CALL add_employee('Chocolate', null, null, null, 'Junior', '13');

-- EXPECTED FAIL
-- Use same existing mobile
CALL add_employee('Strawberry', null, '9277300539', null
, 'Junior', '13');

-- EXPECTED PASS
-- Use same existing home and office number
CALL add_employee('Mint', '5081738778', null, '8295420783
', 'Junior', '13');


-- OTHER DATA FOR TESTING - ALL PASS
CALL add_employee('Ripple', '2360916698', '9572403478', '5726770593
', 'Senior', '13');

CALL add_employee('Pear', '2360916698', '2603541543', '5726770593
', 'Manager', '13');

CALL add_employee('Durian', '5081738778', null, '8295420783
', 'Junior', '14');

CALL add_employee('Apple', '2360916698', '1682432728', '5726770593
', 'Senior', '14');

CALL add_employee('Orange', '2360916698', '8454539596', '5726770593
', 'Manager', '14');