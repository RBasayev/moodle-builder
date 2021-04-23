#!/bin/bash
# export DEBIAN_FRONTEND=noninteractive
# apt-get update
# apt-get -y install jq postgresql-client
# zendphpctl EXT install pgsql xml mbstring curl zip gd intl xmlrpc soap

# checking the version provided in the script argument
filter="$(echo $1 | grep -E '[3-5]\.[0-9]+')"
if [ -z "$filter" ]; then
cat <<EOU
Usage: $0 <version in form X.X or X.XX>

Expected: 3.x (current), 4.x (next) or 5.x (not even planned yet).
Examples:
    $0 3.11
    $0 4.2
    $0 5.03

EOU
exit 1
fi

url=moodle.build.lcl
pghost=pg-4-imoo
pgdb=imoodb
pguser=imoouser
pgpass=imoopassword

tss=$(date +%s)
echo "Starting at $(date)"

cd /var/www/site

function dumpStatus() {
    # Usage:
    #     dumpStatus init
    #     dumpStatus get
    #     dumpStatus set <value>, e.g. "dumpStatus set wait"

    # not verifying input ($2), only enforcing length, counting on smart caller
    word=$1
    new=${2:0:4}

    dumpStatus.php $pghost $pgdb $pguser $pgpass $word $new 2> /dev/null

}

echo "Getting Moodle"
rel=$(curl -sL "https://api.github.com/repos/moodle/moodle/tags" | jq '.[].name' | tr -d '"v' | grep "$filter" | sort -rV | head -1)

curl -sLo moodle.tgz https://github.com/moodle/moodle/archive/refs/tags/v$rel.tar.gz

echo "Unpacking Moodle"
tar xf moodle.tgz
mv moodle-$rel/* .
rm -rf moodle-$rel moodle.tgz

w=0
while ! dumpStatus init > /dev/null; do
    sleep 2
    if [ $w -gt 60 ]; then
        # 2 minutes should have been more than enough
        echo "Have been trying for 2 minutes to connect to the DB. Enough!"
        exit 1
    fi
    ((w=w+1))
done
sleep 1

echo "Installing Moodle"
# switching the watcher on DB end to 10-second cycles
dumpStatus set wait

php /var/www/site/admin/cli/install.php \
        --non-interactive \
        --agree-license \
        --wwwroot="http://$url" \
        --dbtype=pgsql \
        --dbhost=$pghost \
        --dbname=$pgdb \
        --dbuser=$pguser \
        --dbpass=$pgpass \
        --fullname="Instant Moodle" \
        --shortname=IMoo \
        --summary="Digestible Instant Moodle Package" \
        --adminuser=su \
        --adminpass=imoosupass \
        --adminemail="admin@$url"

echo "Packaging Moodle"
sleep 1
dumpStatus set 'now!'

sed -i "s|$pghost|@-DB-HOST-@|g" /var/www/site/config.php
sed -i "s|$pgdb|@-DB-DB-@|g" /var/www/site/config.php
sed -i "s|$pguser|@-DB-USER-@|g" /var/www/site/config.php
sed -i "s|$pgpass|@-DB-PASS-@|g" /var/www/site/config.php
sed -i "s|/var/www|@-APP-ROOT-@|g" /var/www/site/config.php
sed -i "s|$url|@-SITE-URL-@|g" /var/www/site/config.php


cp /opt/zpk/cron2jq.php /var/www/site/admin/cli/

mkdir /opt/toPack
mv /var/www /opt/toPack/
cp -R /opt/zpk/scripts /opt/toPack/
cp /opt/zpk/imoo.png /opt/zpk/LICENSE.txt /opt/toPack/
sed "s|@-MOO-VER-@|$rel|g" /opt/zpk/deployment.xml > /opt/toPack/deployment.xml

echo "That dump should be here any minute."
t=0
while [ "$(dumpStatus get)" != "done" ]; do
    sleep 3
    if [ $t -gt 40 ]; then
        # 2 minutes should have been more than enough
        echo "Not getting 'done' from my friend making the DB dump. I'm worried..."
        exit 1
    fi
    ((t=t+1))
done
echo "Got the dump. Thank you!"
dumpStatus set 'over'


cp /opt/dbdump/imoo.SQL /opt/toPack/scripts/
cd /opt/toPack/
zip -9 -qr /tmp/InstantMoodle-$rel.zip *
cp /tmp/InstantMoodle-$rel.zip /opt/zpk-out/InstantMoodle-$rel.zpk

tse=$(date +%s)
echo "Ended at $(date)"
echo "Total of $(($tse-$tss)) seconds"

