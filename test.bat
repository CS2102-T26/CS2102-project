set PGPASSWORD=iamPoopypoop1
set PGDATABASE=cs2102_tp
psql -U postgres -w -f schema.sql
psql -U postgres -w -f data.sql
psql -U postgres -w -f DummyData/Departments.sql
psql -U postgres -w -f DummyData/Employees.sql
psql -U postgres -w -f DummyData/HealthDeclaration.sql
psql -U postgres -w -f DummyData/Juniors.sql
psql -U postgres -w -f DummyData/MeetingRooms.sql
psql -U postgres -w -f DummyData/LocatedIn.sql
psql -U postgres -w -f DummyData/Sessions.sql
psql -U postgres -w -f DummyData/WorksIn.sql
psql -U postgres -w -f DummyData/Updates.sql
psql -U postgres -w -f DummyData/JoinsBooksApproves.sql
psql -U postgres -w -f proc.sql