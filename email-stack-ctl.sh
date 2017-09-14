#!/bin/bash

set -ex

# roundcube release version to use
#RELEASE='1.3.1'
# base docker image that contains sqlit3 for database initialization
#BASE='mechleg/base'
# volume name, needs to match docker-compose naming conventions: <cluster>_<volumename>
#DATA_VOL='emailstack_webmaildata'
# random string used to generate the aes-256 key
#KEY_IN='mechlegmail'

#APP='email-stack'
APPDIR=$(dirname $0)

#if [ -d "../${APP}" ]; then
#  APPDIR=$(pwd)
#elif [ -d "/opt/${APP}" ]; then
#  APPDIR="/opt/${APP}"
#fi

if [ -f "${APPDIR}/.env" ]; then
  source ${APPDIR}/.env
else
  exit 1
fi

KEY_OUT=$(openssl enc -aes-256-cbc -k ${KEY_IN} -P -md sha256|awk -F= '/^key/ {print $2}')

build_roundcube_volume() {
  if [ $# -ne 0 ]; then
    VOLUME=$1
  else
    exit 1
  fi

  if [ ! -e "/tmp/roundcubemail-${RELEASE}" ]; then
    wget -qO- "https://github.com/roundcube/roundcubemail/releases/download/${RELEASE}/roundcubemail-${RELEASE}-complete.tar.gz" | tar -C /tmp -xz
    rm -rf "/tmp/roundcubemail-${RELEASE}/installer"
  fi
  
#  sed -i -e "s/\(.*des_key.\+=\).*/\1 \'${KEY_OUT}\';/g" webmail/config.inc.php
  
  docker volume create --name ${VOLUME}
  MOUNT=$(docker volume inspect ${VOLUME} | python -c "import sys, json; print json.load(sys.stdin)[0]['Mountpoint']")
  
  if [ ! -d "${MOUNT}/src" ]; then
    echo "webmail source not found in ${VOLUME}, creating now"
    sed -e "s/\${SERVERNAME}/${SERVERNAME}.${DOMAIN}/g" -e "s/\${DOMAIN}/${DOMAIN}/g" -e "s|\${SUPPORT}|${SUPPORT}|g" -e "s/\(.*des_key.\+=\).*/\1 \'${KEY_OUT}\';/g" ${APPDIR}/webmail/config.inc.php.tmpl > ${APPDIR}/webmail/config.inc.php
    # create a shim container to do some copy operations into the volume
    DOCKER=$(docker run -d -v ${VOLUME}:/var/lib/roundcube ${BASE})
    # copy roundcube source to volume
    docker cp /tmp/roundcubemail-${RELEASE} ${DOCKER}:/var/lib/roundcube/src
    # copy roundcube configs to volume
    docker cp ${APPDIR}/webmail/config.inc.php ${DOCKER}:/var/lib/roundcube/src/config
    # remove the shim container, remaining operations can use docker run
    docker stop ${DOCKER} && docker rm ${DOCKER}
    # roundcube does not like the nginx mime.types, grabbing the Apache version
    docker run --rm -v ${VOLUME}:/var/lib/roundcube ${BASE} curl -Sso /var/lib/roundcube/mime.types 'http://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types'
    # everything owned by the user that also owns the php-fpm process
    docker run --rm -v ${VOLUME}:/var/lib/roundcube ${BASE} chown -R 65534 /var/lib/roundcube/
    # initialize roundcube sqlite database
    docker run --rm -v ${VOLUME}:/var/lib/roundcube ${BASE} su -s /bin/sh -c 'sqlite3 /var/lib/roundcube/sqlite.db < /var/lib/roundcube/src/SQL/sqlite.initial.sql' nobody
  #docker exec -it ${DOCKER:0:12} curl -Sso /var/lib/roundcube/mime.types 'http://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types'
  #docker exec -it ${DOCKER:0:12} chown -R 65534 /var/lib/roundcube/
  #docker exec -it ${DOCKER:0:12} su -s /bin/sh -c 'sqlite3 /var/lib/roundcube/sqlite.db < /var/lib/roundcube/src/SQL/sqlite.initial.sql' nobody
  #docker exec fpm chown -R 65534 /var/lib/roundcube/
  #docker exec fpm su -s /bin/sh -c 'sqlite3 /var/lib/roundcube/sqlite.db < /var/lib/roundcube/src/SQL/sqlite.initial.sql' nobody
  else
    echo "found webmail source in ${VOLUME}, nothing changed"
  fi
}

case $1 in
  createvol)
    if [ $# -eq 2 ]; then
      build_roundcube_volume $2
    else
      build_roundcube_volume ${DATA_VOL}
    fi
    ;;
  delete)
    docker-compose -f ${APPDIR}/docker-compose.yml down -v
    ;;
#  restart)
#    docker-compose -f ${APPDIR}/docker-compose.yml down
#    docker-compose -f ${APPDIR}/docker-compose.yml up
#    ;;
  start)
#    build_roundcube_volume ${DATA_VOL}
    docker-compose -f ${APPDIR}/docker-compose.yml up
#    docker-compose -f ${APPDIR}/docker-compose.yml config
#    docker-compose -f ${APPDIR}/docker-compose.yml up -d
    ;;
  startd)
    docker-compose -f ${APPDIR}/docker-compose.yml up -d
    ;;
  stop)
#    docker-compose down
    docker-compose -f ${APPDIR}/docker-compose.yml down
    ;;
  *)
    exit 1
    ;;
esac

#docker-compose up -d
