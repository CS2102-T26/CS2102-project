echo TESTING contact_tracing
psql -w -f Test-contact_tracing.sql
echo TESTING declare_health
psql -w -f Test-declare_health.sql
