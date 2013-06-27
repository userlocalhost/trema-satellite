#!/usr/bin/bash

./make_traffic.sh host1 host2 &
./make_traffic.sh host1 host3 &
./make_traffic.sh host1 host4 &
./make_traffic.sh host2 host4
