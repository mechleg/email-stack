#!/bin/bash

#set -ex

APPDIR=$(dirname $0)

if [ -f "${APPDIR}/.env" ]; then
  source ${APPDIR}/.env
else
  exit 1
fi

KEY_OUT=$(openssl enc -aes-256-cbc -k ${KEY_IN} -P -md sha256 | awk -F= '/^key/ {print $2}')

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

  if VOL_INFO=$(docker volume inspect ${VOLUME}); then
    MOUNT=$(echo ${VOL_INFO} | python -c "import sys, json; print json.load(sys.stdin)[0]['Mountpoint']")
  else
    echo "webmail volume not found, creating now"
    docker volume create --name ${VOLUME}
    MOUNT=$(docker volume inspect ${VOLUME} | python -c "import sys, json; print json.load(sys.stdin)[0]['Mountpoint']")
  fi
  
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
  start)
    docker-compose -f ${APPDIR}/docker-compose.yml up
    ;;
  startd)
    # start in daemon mode
    docker-compose -f ${APPDIR}/docker-compose.yml up -d
    ;;
  stop)
    docker-compose -f ${APPDIR}/docker-compose.yml down
    ;;
  *)
    exit 1
    ;;
esac
