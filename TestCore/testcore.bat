echo TESTING search_room
psql -w -f Test-search_room.sql
echo TESTING book_room
psql -w -f Test-book_room.sql
echo TESTING join_meeting
psql -w -f Test-join_meeting.sql
echo TESTING leave_meeting
psql -w -f Test-leave_meeting.sql
echo TESTING approve_meeting
psql -w -f Test-approve_meeting.sql
echo TESTING unbook_room
psql -w -f Test-unbook_room.sql