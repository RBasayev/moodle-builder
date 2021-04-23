<?php


$sqlFile = "$scriptsDir/imoo.SQL";
replace_in_file($sqlFile, array(
   '@-SITE-URL-@' => $hostName,
   '@-APP-ROOT-@' => $appBaseDir
));


// maybe not the best idea to connect to the postgres database first...
$link = pg_connect("host=$dbHost port=5432 user=$dbUsername password=$dbPassword dbname=postgres");
check($link, 'Could not connect to the PostgreSQL Server.');

$res = pg_query($link, 'SHOW server_version;');
$ver = pg_fetch_row($res)[0];
check((substr($ver, 0, 2) > 12), 'The PostgreSQL Server version must be at least 13.');

// fresh database
$res = pg_query($link, "DROP DATABASE IF EXISTS $dbName;");
check($res, 'Failed to DROP the database (if it even exists).');
$res = pg_query($link, "CREATE DATABASE $dbName WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';");
check($res, 'Failed to create the database.');


/* safer block BEGIN
# this block is a different approach than the DROP DATABASE, which is potentially dangerous

$res = pg_query($link, "SELECT datname FROM pg_database WHERE datname='$dbName';");
check($res, 'Could not get the list of databases.');

if (pg_fetch_row($res)[0] != $dbName) {
   $res = pg_query($link, "CREATE DATABASE $dbName WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';");
   check($res, 'Failed to create the database.');
}
safer block END */


// need to connect to the actual database now
pg_close($link);
$link = pg_connect("host=$dbHost port=5432 user=$dbUsername password=$dbPassword dbname=$dbName");
check($link, 'Could not connect to the PostgreSQL Server.');



require_once "$scriptsDir/sql_parse.php";

$sqlFull = file_get_contents($sqlFile);

$sqlCommands = split_sql_file($sqlFull, ';');
foreach ($sqlCommands as $query) {
   $query = trim($query);
   if (!empty($query)) {
      $res = pg_query($link, $query);
      check($res, 'Invalid query [' . $query . ']: ' . pg_last_error($link));
   }
}
