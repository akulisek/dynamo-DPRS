#get log server ip from consul
IP=$(curl http://$CONSUL_IP:8500/v1/kv/logserver?raw)

#set the ip in rsyslog config
sed -i "s/172.17.0.2/$IP/g" /etc/rsyslog.d/test.conf

#start rsyslog
rsyslogd

#start tomcat
catalina.sh run