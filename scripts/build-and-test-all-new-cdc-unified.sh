#!/bin/bash

set -e

if [ -z "$DOCKER_COMPOSE" ]; then
    echo setting DOCKER_COMPOSE
    export DOCKER_COMPOSE="docker-compose -f docker-compose-unified.yml -f docker-compose-new-cdc-unified.yml"
else
    echo using existing DOCKER_COMPOSE = $DOCKER_COMPOSE
fi

./gradlew assemble

. ./scripts/set-env-mysql.sh

$DOCKER_COMPOSE stop
$DOCKER_COMPOSE rm --force -v

$DOCKER_COMPOSE build
$DOCKER_COMPOSE up -d mysql postgrespollingpipeline mysqlbinlogpipeline postgreswalpipeline

./scripts/wait-for-mysql.sh
export MYSQL_PORT=3307
./scripts/wait-for-mysql.sh

./scripts/wait-for-postgres.sh
export POSTGRES_PORT=5433
./scripts/wait-for-postgres.sh

$DOCKER_COMPOSE up -d

./scripts/wait-for-services.sh $DOCKER_HOST_IP 8099

export SPRING_DATASOURCE_URL=jdbc:mysql://${DOCKER_HOST_IP}:3307/eventuate

./gradlew :eventuate-local-java-jdbc-tests:test

. ./scripts/set-env-postgres-polling.sh
./gradlew :eventuate-local-java-jdbc-tests:test

. ./scripts/set-env-postgres-wal.sh
export SPRING_DATASOURCE_URL=jdbc:postgresql://${DOCKER_HOST_IP}:5433/eventuate
./gradlew :eventuate-local-java-jdbc-tests:test

$DOCKER_COMPOSE stop
$DOCKER_COMPOSE rm --force -v