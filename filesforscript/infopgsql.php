<?php
$VHOSTNAME = 'VIRTUALHOST';
echo "This is VirtualHost $VHOSTNAME!<br />\n";
$dbname = 'DBNAME';
$dbuser = 'DBUSER';
$dbpass = 'DBPASS';
$dbhost = 'localhost';
$dbconn = pg_connect("host=$dbhost port=5432 dbname=$dbname user=$dbuser password=$dbpass") or die("Could not connect");
  $stat = pg_connection_status($dbconn);
  if ($stat === PGSQL_CONNECTION_OK) {
      echo "Connection status is ok on database '$dbname' with user '$dbuser'";
  } else {
      echo 'Connection status bad';
  }
?>
