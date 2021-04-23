<?php

ini_set ( "display_errros", 1 );
ini_set ( "error_reporting", E_ALL );

$scriptsDir = dirname(__FILE__);

/*****************************************************************************
 * Helper Functions
****************************************************************************/


/**
 * Get environment variable
 * 
 * @return string
 */
function getEnvVar($name) {
	$envVar = getenv($name);
	if (! $envVar) {
		exit_with_error($name . ' env var undefined');
	}

	return $envVar;
}

/**
 * Exit with an error message and exit code 1
 *
 * This function exits the program and never returns
 *
 * @param string $error
 * @return void
 */
function exit_with_error($error) {
	echo "ERROR: $error" . PHP_EOL;
	error_log("Zend Deployment: $error");
	exit(1);
}

/**
 * Replace a set of values in a file
 *
 * If '$return' is true, will return the configured data instead of saving to a file
 *
 * @param string  $file
 * @param array   $translate
 * @param boolean $return
 * @return null | string
 */
function replace_in_file($file, $translate) {
	if (($configData = file_get_contents($file)) === false)  {
		exit_with_error("Unable to load data from $file");
	}

	$configData = str_replace(array_keys($translate), array_values($translate), $configData);

	if (! (file_put_contents($file, $configData))) {
		exit_with_error("Unable to write data to $file");
	}
}


/**
 * Check that a (database related) resource is not FALSE
 *
 * @param resource  $rsrc
 * @param string  $errmsg
 * @return void
 */
function check($rsrc, $errmsg)
{
    if ($rsrc === false) {
        exit_with_error($errmsg);
    }
    return true;
}
