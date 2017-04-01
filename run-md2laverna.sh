#!/bin/bash

COMPOSE_FILE=./docker-compose.yml
docker-compose -f $COMPOSE_FILE run md2laverna
