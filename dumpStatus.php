#!/usr/bin/php
<?php
// Why not simply install psql? Because the version in the distro doesn't match the server.
// Why do this through the database at all? Because a trivial filesystem flag would be lame.

// Not sanitizing any of these - this would be premature optimization:
$pghost = $argv[1];
$pgdb   = $argv[2];
$pguser = $argv[3];
$pgpass = $argv[4];
$word   = $argv[5];
$new    = $argv[6];


switch ($word) {
    case 'init':
        $q  = "CREATE UNLOGGED TABLE IF NOT EXISTS public.imoo_build (dump character varying(4) DEFAULT 'soon');";
        $q .= "TRUNCATE TABLE public.imoo_build;";
        $q .= "INSERT INTO public.imoo_build DEFAULT VALUES;";
        break;
    case 'get':
        $q = "SELECT * FROM public.imoo_build;";
        break;
    case 'set':
        $q = "UPDATE public.imoo_build SET dump='$new';";
        break;     
    default:
        echo "Unknown command. Make up your mind.\n";
        exit(1);
        break;
}

$c = pg_connect("host=$pghost port=5432 dbname=$pgdb user=$pguser password=$pgpass");
$r = pg_query($c, $q);
if( !$r ) {
    echo "Houston, we have... you know...\n";
    exit(1);
}

echo ($word=="get") ? pg_fetch_row($r)[0] : '';
