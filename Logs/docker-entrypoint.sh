#file used by logstash image, modified
#!/bin/bash

set -e

# PUT logserver ip into consul
curl -X PUT -d $LOG_HOST_IP http://$CONSUL_IP:8500/v1/kv/logserver

# Add logstash as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- logstash "$@"
fi

# Run as user "logstash" if the command is "logstash"
if [ "$1" = 'logstash' ]; then
	set -- gosu logstash "$@"
fi

exec "$@"