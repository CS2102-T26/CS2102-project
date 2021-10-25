-- EXPECTED PASS
CALL remove_department(8);

-- EXPECTED FAIL (no dept did = 8 or 9);
CALL remove_department(8);
CALL remove_department(9);

-- DIAGNOSTICS
SELECT * FROM WorksIn WHERE did = 8;
SELECT * FROM LocatedIn WHERE did = 8;