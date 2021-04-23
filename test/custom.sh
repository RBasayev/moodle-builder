#!/bin/bash

# woraround for the official image's quiet behavior
zsinfo


WEB_API_SECRET="$(cat /var/zs-xchange/web_api_secret)"
/usr/local/zend/bin/zs-manage  extension-on -e xmlrpc -N docker -K $WEB_API_SECRET
/usr/local/zend/bin/zs-client.sh vhostAdd --name="instant.moodle.lcl" --port=80 --zskey=docker --zssecret=$WEB_API_SECRET --output-format=kv > /dev/null
if [ "$?" != "0" ]; then exit 1; fi
echo "Sucessfully added the VHost. Restarting..."
/usr/local/zend/bin/zs-manage restart -N docker -K $WEB_API_SECRET

# finding the latest (probably the only) ZPK
zpkFile="$(ls -1 /usr/local/zend/tmp/ZPKs/InstantMoodle*.zpk | sort | tail -1)"

depl="$(/usr/local/zend/bin/zs-client.sh applicationDeploy --appPackage="$zpkFile" --baseUrl="http://instant.moodle.lcl" --userAppName="Instant Moodle" --userParams="db_host=postgres&db_username=imoouser&db_password=imoopassword&db_name=imoodb&site_url=http://instant.moodle.lcl" --zskey=docker --zssecret=$WEB_API_SECRET --output-format=kv)"

app=$(echo "$depl" | grep 'applicationInfo\[id\]=' | cut -d'=' -f2)
echo "Application ID: $app"


for i in {1..10}; do
    info="$(/usr/local/zend/bin/zs-client.sh applicationGetStatus --applications=$app --zskey=docker --zssecret=$WEB_API_SECRET --output-format=kv)"
    stus=$(echo "$info" | grep 'applicationsList\[0\]\[status\]=' | cut -d'=' -f2)
    echo "Deployment status:   $stus"
    [[ "$stus" == "deployed" ]] && break
    sleep 8
done
if [ "$stus" != "deployed" ]; then
    echo "We waited for about minute and a half - Instant Moodle"
    echo "still doesn't seem to be deployed. You should check the UI."
fi

lctn=$(echo "$info" | grep 'applicationsList\[0\]\[installedLocation\]=' | cut -d'=' -f2)

# The jobqueueCreateQueue WebAPI method doesn't seem to have a way to provide a CLI job timeout 
qcrt="$(/usr/local/zend/bin/zs-client.sh jobqueueCreateQueue --name=CRON --http_job_timeout=250 --http_job_retry_count=1 --http_job_retry_timeout=20 --zskey=docker --zssecret=$WEB_API_SECRET --output-format=kv)"
if echo "$qcrt" | grep 'result=success' > /dev/null 2>&1 ;then
    echo "The CRON queue has been created successfully"
    env ZQ_NAME=CRON php "$lctn/site/admin/cli/cron2jq.php"
fi


