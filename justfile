#!/usr/bin/env just --justfile
# SETTINGS
# set dotenv-load := true
export DATABASE_URL :="postgres://postgres:mySuperSecretPassword!@localhost:5432/postgres?sslmode=disable"
export DB_PASSWORD:="mySuperSecretPassword!" # Remember to update the DATABASE_URL
export DB_PORT:="5432" # Remember to update the DATABASE_URL
export DB_TAG:="wisp_kv_sessions_postgres_store"


# DB
db_create:
	docker run -d \
	 -p $DB_PORT:5432 \
	 -e POSTGRES_PASSWORD=$DB_PASSWORD \
	 --name $DB_TAG \
	 postgres

db_start:
	docker start $DB_TAG

db_stop:
	docker stop $DB_TAG

db_inspect:
	docker exec -it $DB_TAG psql -h localhost -U postgres




