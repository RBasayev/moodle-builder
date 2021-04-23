FROM rbasayev/zendphp:ubuntu20-php74
COPY dumpStatus.php /usr/local/bin/dumpStatus.php
COPY build.sh /usr/local/bin/build.sh
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get -y install jq postgresql-client zip; \
    zendphpctl EXT install pgsql xml mbstring curl zip gd intl xmlrpc soap; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir /var/www/moodledata /var/www/site; \
    chown web:site /var/www/moodledata; \
    chmod a+x /usr/local/bin/*
