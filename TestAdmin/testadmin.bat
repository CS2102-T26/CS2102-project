echo TESTING non_compliance
psql -w -f Test-non_compliance.sql
echo TESTING view_booking_report
psql -w -f Test-view_booking_report.sql
echo TESTING view_future_meeting
psql -w -f Test-view_future_meeting.sql
echo TESTING view_managager_report
psql -w -f Test-view_manager_report.sql

