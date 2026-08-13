-- Read-only diagnostics for LOAD DATA LOCAL INFILE failures.

SELECT VERSION() AS mysql_version,
       @@port AS server_port,
       @@hostname AS server_hostname,
       @@global.local_infile AS global_local_infile,
       @@session.time_zone AS session_time_zone,
       @@system_time_zone AS system_time_zone;

SHOW VARIABLES LIKE 'local_infile';
SHOW VARIABLES LIKE 'secure_file_priv';

