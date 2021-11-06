-- EXPECTED TO SHOW ALL THESE EMPLOYEES (except 291 and 261)
insert into Sessions (time, date, floor, room) values ('10:00:00', '2022-10-22', 4, 5);
CALL book_room(4, 5, '2022-10-22', '10:00:00', '11:00:00', 261); 
insert into Joins (eid, time, date, floor, room) values (13, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (174, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (124, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (116, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (165, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (134, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (154, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (145, '10:00:00', '2022-10-22', 4, 5);
insert into Joins (eid, time, date, floor, room) values (164, '10:00:00', '2022-10-22', 4, 5);
insert into Approves (eid, time, date, floor, room) values (299, '10:00:00', '2022-10-22', 4, 5);
insert into HealthDeclaration (eid, date, temp) values (261, '2022-10-23', 37.7);
select contact_tracing(261);

-- EXPECTED TO NOT SHOW ANYTHING
insert into HealthDeclaration (eid, date, temp) values (261, '2022-10-24', 36.7);
select contact_tracing(261);
