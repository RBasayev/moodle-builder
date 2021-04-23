#!/bin/bash

trap exit SIGTERM

docker-entrypoint.sh postgres &

url=moodle.build.lcl
pghost=pg-4-imoo
pgdb=imoodb
pguser=imoouser
pgpass=imoopassword

opts=" --blobs --format=p --no-owner --exclude-table=public.imoo_build --no-privileges --no-acl --inserts --column-inserts --attribute-inserts --rows-per-insert=30 "

echo "localhost:5432:$pgdb:$pguser:$pgpass" > /root/.pgpass
chmod 600 /root/.pgpass

t=15
dump="no"
while [ "a" != "b" ]; do
    case $dump in
        'wait')
            # the build script is working, shorter time out
            if [ $t -gt 7 ]; then
                echo "Preparing to be ready..."
            fi
            t=7
            ;;
        'now!')
            # dump and set placeholders
            echo "Initiating Moodle database dump..."
            psql -h localhost -U $pguser -p 5432 -d $pgdb -w -tc "UPDATE public.imoo_build SET dump='runs';"
            pg_dump $opts -h localhost -U $pguser -p 5432 -d $pgdb -w -f /output/imoo.SQL
            sed -i "s|$url|@-SITE-URL-@|g" /output/imoo.SQL
            sed -i "s|/var/www|@-APP-ROOT-@|g" /output/imoo.SQL
            sed -ri -e 's|^--.*$||g' -e '/^\s*$/d' /output/imoo.SQL
            psql -h localhost -U $pguser -p 5432 -d $pgdb -w -tc "UPDATE public.imoo_build SET dump='done';"
            echo "                                      done!"
            t=8
            ;;
        'done')
            # short timeout, 'over' comes quickly
            t=5
            ;;
        'over')
            echo "My dumping here is done. Where is the exit 0?"
            exit 0
            ;;
        *)
            # default time out
            t=15
            ;;
    esac
    sleep $t
    dump=$(psql -h localhost -U $pguser -p 5432 -d $pgdb -w -tc "SELECT dump FROM public.imoo_build;" 2> /dev/null | tr -d [:space:])
done
