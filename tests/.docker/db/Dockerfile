FROM mysql:5.7

ENV MYSQL_ALLOW_EMPTY_PASSWORD false

COPY tests/.docker/db/schema/*.sql /docker-entrypoint-initdb.d/
