-- Expected Pass (3 days not declared)
insert into HealthDeclaration (eid, date, temp) values (1, '2021-12-01', 35.6);
insert into HealthDeclaration (eid, date, temp) values (1, '2021-12-02', 35.4);
insert into HealthDeclaration (eid, date, temp) values (1, '2021-12-03', 35.5);
insert into HealthDeclaration (eid, date, temp) values (1, '2021-12-05', 35.3);
insert into HealthDeclaration (eid, date, temp) values (1, '2021-12-06', 35.2);
insert into HealthDeclaration (eid, date, temp) values (1, '2021-12-07', 35.1);
insert into HealthDeclaration (eid, date, temp) values (1, '2021-12-09', 34.7);
insert into HealthDeclaration (eid, date, temp) values (2, '2021-12-02', 35.2);
insert into HealthDeclaration (eid, date, temp) values (2, '2021-12-03', 34.9);
insert into HealthDeclaration (eid, date, temp) values (2, '2021-12-04', 36.1);
insert into HealthDeclaration (eid, date, temp) values (2, '2021-12-05', 34.9);
insert into HealthDeclaration (eid, date, temp) values (2, '2021-12-07', 35.4);
insert into HealthDeclaration (eid, date, temp) values (2, '2021-12-08', 35.5);
insert into HealthDeclaration (eid, date, temp) values (2, '2021-12-09', 35.7);
select * from non_compliance('2021-12-01', '2021-12-10') where eid = 1 or eid = 2;

-- Expected Pass (Descending Days) Order eid 3 5, eid 1 3, eid 2 2
select * from non_compliance('2021-12-07', '2021-12-11') where eid = 1 or eid = 2 or eid = 3;

-- Expected Fail (All days declared) 0 rows returned
insert into HealthDeclaration (eid, date, temp) values (1, '2021-12-04', 36.1);
insert into HealthDeclaration (eid, date, temp) values (2, '2021-12-06', 35.2);
select * from non_compliance('2021-12-02', '2021-12-07') where eid = 1 or eid = 2;
