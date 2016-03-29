#!/usr/bin/env bash

res=$(curl -X PUT -d $LOG_HOST_IP http://$CONSUL_IP:8500/v1/kv/logserver)
echo $res
