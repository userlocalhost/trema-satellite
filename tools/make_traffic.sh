#!/bin/bash

src_host=$1
dst_host=$2

if [ -z "${src_host}" -o -z "${dst_host}" ]
then
	echo "Usage: ./this <src_host> <dst_host>"
	exit
fi

while [ 1 ]
do
	${TREMA_HOME}/trema send_packets --source ${src_host} --dest ${dst_host} --n_pkts 1 --length $(( (RANDOM % 1000) + 10))

	sleep 1
done
