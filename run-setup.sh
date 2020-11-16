#!/usr/bin/env bash

set -e

db_hostname='musicbrainz-db'
db_password='musicbrainz'
db_user='musicbrainz'
db_name='musicbrainz_db'
DB_DATA_DIR='/mnt/data'
DB_DATA_DIR_HOST="$PWD/data/postgresql-data"
FTP_DATA="$PWD/data/ftp-data"
network_name='musicbrainz'
if ! docker network inspect $network_name >/dev/null; then
    docker network create $network_name
fi
if [ ! -d "$FTP_DATA" ]; then
    mkdir -p $FTP_DATA
    cd $FTP_DATA
    wget -r -np http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/
    cd -
fi
if ! docker inspect $db_hostname >/dev/null 2>/dev/null; then
    docker run -d \
        --rm \
        --name $db_hostname \
        --network $network_name \
        -e POSTGRES_PASSWORD="$db_password" \
        -e POSTGRES_USER="$db_user" \
        -e POSTGRES_DB="$db_name" \
        -e PGDATA="$DB_DATA_DIR" \
        -e POSTGRES_INITDB_ARGS="-D $DB_DATA_DIR" \
        -v $DB_DATA_DIR_HOST:$DB_DATA_DIR:rw \
        postgres:12
fi
docker stop $db_hostname >/dev/null
docker run -d \
   --rm \
   --name $db_hostname \
   --network $network_name \
   -e POSTGRES_PASSWORD="$db_password" \
   -e POSTGRES_USER="$db_user" \
   -e POSTGRES_DB="$db_name" \
   -e PGDATA="$DB_DATA_DIR" \
   -e POSTGRES_INITDB_ARGS="-D $DB_DATA_DIR" \
   -v $DB_DATA_DIR_HOST:$DB_DATA_DIR:rw \
   -v $PWD/configs/pg_hba.conf:$DB_DATA_DIR/pg_hba.conf:rw \
   postgres:12

db_ipaddress=$(docker inspect $db_hostname|jq -r ".[0].NetworkSettings.Networks.$network_name.IPAddress")
sed "s/{{DBHOST_IP}}/$db_ipaddress/g" ./configs/DBDefs.pm.tmpl > ./configs/DBDefs.pm
docker build . -t musicbrainz-server:latest -f Dockerfile
echo 'Connect with:'
echo "  docker run --rm -it --name musicbrainz-server -v $FTP_DATA:/opt/ftp-data:ro --network $network_name musicbrainz-server:latest /bin/bash"
echo 'And run the command:'
echo "  ./admin/InitDb.pl --clean --import /opt/ftp-data/ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/20200926-001708/mbdump-*.tar.bz2 --echo"
exit 0
