#!/bin/bash

SQLDIR='../src/sql'
DB_USER='user'
DB_PASSWD='password'

mysql -u${DB_USER} -p${DB_PASSWORD} < ${SQLDIR}/init.sql
