<?php
$VHOSTNAME = 'VIRTUALHOST';
echo "This is VirtualHost $VHOSTNAME!<br />\n";
$dbname = 'DBNAME';
$dbuser = 'DBUSER';
$dbpass = 'DBPASS';
$dbhost = 'localhost';

$connect = mysql_connect($dbhost, $dbuser, $dbpass) or die("Unable to Connect to '$dbhost'");
mysql_select_db($dbname) or die("Could not open the db '$dbname'");
$test_query = "SHOW TABLES FROM $dbname";
$result = mysql_query($test_query);
$tblCnt = 0;
while($tbl = mysql_fetch_array($result)) {
  $tblCnt++;
}
if (!$tblCnt) {
  echo "Connected to '$dbname' with '$dbuser' but There are no tables<br />\n";
} else {
  echo "Connected to '$dbname' with '$dbuser' and There are $tblCnt tables<br />\n";
}
?>
