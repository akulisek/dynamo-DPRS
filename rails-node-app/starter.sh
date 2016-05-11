#get log server ip from consul
IP=$(curl http://$CONSUL_IP:8500/v1/kv/logserver?raw)

#set the ip in rsyslog config
sed -i "s/172.17.0.2/$IP/g" /etc/rsyslog.d/test.conf
#start rsyslog
/etc/init.d/rsyslog start

#start rails
echo "change directory"
cd /home/rails/webapp
echo "start rails server"
export SECRET_KEY_BASE=$(bundle exec rake secret)
export CONTAINER_ADDRESS="$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | grep 192.168.0):3000"
rails server --binding 0.0.0.0

