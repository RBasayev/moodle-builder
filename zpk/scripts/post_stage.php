<?php
/* The script post_stage.phpwill be executed after the staging process ends. This will allow
 * users to perform some actions on the source tree or server before an attempt to
 * activate the app is made. For example, this will allow creating a new DB schema
 * and modifying some file or directory permissions on staged source files
 * The following environment variables are accessable to the script:
 * 
 *   - ZS_APPLICATION_BASE_DIR - Contains the directory to which the application is deployed
 *   - ZS_CURRENT_APP_VERSION - In case an upgrade was performed, contains the version number of the current application
 *   - ZS_PHP_VERSION - Contains the PHP version that Zend Server uses
 *   - ZS_PREVIOUS_APP_VERSION - In case a rollback was performed, contains the previous version of the application
 *   - ZS_PREVIOUS_APPLICATION_BASE_DIR = In case a rollback was performed, contains the directory to which the application was deployed
 *   - ZS_RUN_ONCE_NODE - When deploying in a cluster, a single node ID is chosen to perform actions that only need to be done once. If the value of this constant is set  to ‘1’ during deployment, the node is defined as the ‘run once node’
 *         Important Note about Managed Deployment: When updating an application on a subset of the cluster, the run once mechanism is only applicable to the initial update. When you sync the other nodes with an additional update so all the nodes would have the same application version, the ZS_RUN_ONCE_NODE constant will always be 'false' on hook scripts, as the "run once" code cannot run again (usually a set-up code to align former application version to current, e.g. database scheme, resources etc.).
 *   - ZS_WEBSERVER_GID - Contains the web server user group ID (UNIX only)
 *   - ZS_WEBSERVER_TYPE - Contains a code representing the web server type (APACHE)
 *   - ZS_WEBSERVER_UID - Contains the web server user ID (UNIX only)
 *   - ZS_WEBSERVER_VERSION - Contains the web server version (2.2)
 *   - ZS_BASE_URL = Contains the base URL set for deployment
 *   - ZS_<PARAMNAME> - will contain value of parameter defined in deployment.xml, as specified by
 *   user during deployment.
 */

set_time_limit(-1);

require_once dirname(__FILE__) . '/common.php';

// get the env vars
$appBaseDir     = getEnvVar('ZS_APPLICATION_BASE_DIR');
$baseUrl        = getEnvVar('ZS_SITE_URL');
$dbHost         = getEnvVar('ZS_DB_HOST');
$dbUsername     = getEnvVar('ZS_DB_USERNAME');
$dbPassword     = getEnvVar('ZS_DB_PASSWORD');
$dbName         = getEnvVar('ZS_DB_NAME');

// of course, a more thorough person would have used ZS_WEBSERVER_UID / ..._GID
system("chmod -R 777 '$appBaseDir/moodledata'");

$parsedUrl = parse_url($baseUrl);
check(isset($parsedUrl['host']), "Can't parse $baseUrl");
$hostName = $parsedUrl['host'];

$configFile = $appBaseDir . '/site/config.php';
check(file_exists($configFile), "Configuration file $configFile not found");

replace_in_file($configFile, array(
    '@-DB-HOST-@' => $dbHost,
    '@-DB-DB-@' => $dbName,
    '@-DB-USER-@' => $dbUsername,
    '@-DB-PASS-@' => $dbPassword,
    '@-APP-ROOT-@' => $appBaseDir,
    '@-SITE-URL-@' => $hostName
));


if (getenv("ZS_RUN_ONCE_NODE") == 1) {
    require_once "$scriptsDir/pg.php";
}

echo 'Post Stage Successful';
exit(0);
