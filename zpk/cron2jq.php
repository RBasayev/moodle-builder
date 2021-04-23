<?php
ini_set ( "display_errros", 1 );
ini_set ( "error_reporting", E_ALL );

$cron = dirname(__FILE__) . '/cron.php';

if (!file_exists($cron)) {
    echo "Couldn't find the cron script:\n   $cron\n\n";
    exit(1);
}

$q_name = getenv('ZQ_NAME');
if ($q_name) {
    // If the environment variable ZQ_NAME is set,
    // we assume it has the custom queue name for us
    $jobOptions['queue_name'] = $q_name;
}


$jobOptions['name'] = 'Instant Moodle CRON';
$jobOptions['schedule'] = '*/10 * * * *';
// If failed, we want to try this job twice during the 10 minute
// scheduling interval with 20 second between retries, therefore:
// 10min / 2 - 20sec = 280sec, so 250 is safe enough.
$jobOptions['job_timeout'] = 250;


$queue = new ZendJobQueue();
$jobId = $queue->createPhpCliJob($cron, array(), $jobOptions);
echo "A recurring job with ID '$jobId' has been created.\n\n";
