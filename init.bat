set PGUSER=postgres
set PGPASSWORD=Kingofquackers@07
set PGDATABASE=project_db
psql -w -f schema.sql
psql -w -f data.sql
psql -w -f DummyData/Departments.sql
psql -w -f DummyData/Employees.sql
psql -w -f DummyData/HealthDeclaration.sql
psql -w -f DummyData/Juniors.sql
psql -w -f DummyData/MeetingRooms.sql
psql -w -f DummyData/LocatedIn.sql
psql -w -f DummyData/Sessions.sql
psql -w -f DummyData/WorksIn.sql
psql -w -f DummyData/Updates.sql
psql -w -f DummyData/JoinsBooksApproves.sql
psql -w -f proc.sql