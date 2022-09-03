#!/bin/bash

BASE="$(readlink -nf ${BASH_SOURCE[0]%/*})"

docker rm guacamole -f >/dev/null 2>&1
exec docker run -i -a STDOUT -a STDERR --name guacamole --rm \
    -e GUACD_HOSTNAME=guacd \
    -e GUACD_PORT=4822 \
    -e MYSQL_HOSTNAME=guacamoledb \
    -e MYSQL_DATABASE=guacamole \
    -e MYSQL_USER=guacamole \
    -e MYSQL_PASSWORD=guacamole \
    -e MYSQL_AUTO_CREATE_ACCOUNTS=true \
    -e HEADER_ENABLED=true \
    -e HTTP_AUTH_HEADER=X-CloudSandbox-User-Email \
    -e GUACAMOLE_HOME=/etc/guacamole \
    -v "$BASE/conf:/etc/guacamole:ro" \
    -p 8080:8080 \
    guacamole/guacamole
