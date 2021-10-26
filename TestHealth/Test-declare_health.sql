-- EXPECTED FAIL OUT OF RANGE
CALL declare_health(154, '2022-10-26', 33.9); 
CALL declare_health(154, '2022-10-26', 43.1); 

-- EXPECTED PASS  
CALL declare_health(154, '2022-10-26', 36.9); 
CALL declare_health(154, '2022-10-26', 37.9); 
CALL declare_health(154, '2022-10-26', 38.9); 

-- EXPECTED FAIL EID DOES NOT EXIST
CALL declare_health(454, '2022-10-26', 36.9); 
