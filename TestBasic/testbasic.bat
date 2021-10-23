echo TESTING PROCEDURE add_department
psql -w -f Test-add_department.sql
echo. & echo TESTING PROCEDURE add_employee
psql -w -f Test-add_employee.sql
echo. & echo TESTING PROCEDURE add_room
psql -w -f Test-add_room.sql
echo. & echo TESTING PROCEDURE change_capacity
psql -w -f Test-change_capacity.sql
echo. & echo TESTING PROCEDURE remove_department
psql -w -f Test-remove_department.sql
echo. & echo TESTING PROCEDURE remove_employee
psql -w -f Test-remove_employee.sql