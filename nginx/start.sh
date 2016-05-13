#!/bin/sh
#/etc/init.d/nginx start > /dev/null
service nginx start  > /dev/null
consul-template -consul=$CONSUL_URL -template="/templates/service.ctmpl:/etc/nginx/sites-enabled/default:service nginx reload"
