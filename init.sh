#################################
# init script
#################################
# init variables

REPLICATION="3"
DYN_MAX_KEY="65536"

DS_VM="docker-SD" 
VM_1="sm-docker-0"
VM_2="docker-1"
LOG_VM="docker-LOG"
NETWORK_NAME="private-network"
NETWORK="192.168.0.0/24"
PROXY="proxy"
SD="consul"
SD_IMAGE="consul_instance"
NODE="java_instance"
NODE_IMAGE="java_image"
LOG_IMAGE="elk_image"
LOG_INSTANCE="elk_instance"
RAILS_NODE="rails-webapp"
RAILS_NODE_IMAGE="rails-image"
  
#################################

# making new docker virtual machine with discovery service with virtualbox driver
docker-machine create -d virtualbox $DS_VM

#change to $DS_VM
eval $(docker-machine env $DS_VM)

#run consul docker container 
docker build -t $SD_IMAGE ./Consul/
docker run -d -p "8400:8400" -p "8500:8500" -p "8600:53/udp"  --name $SD $SD_IMAGE -server -bootstrap -ui-dir /ui

DS_IP=$(docker-machine ip $DS_VM)

docker exec $SD /bin/bash /usr/bin/unregister.sh $DS_IP >/dev/null & 

#run new virtual machines swarm and host
docker-machine create -d virtualbox --swarm --swarm-master --swarm-discovery="consul://$DS_IP:8500" --engine-opt="cluster-store=consul://$DS_IP:8500" --engine-opt="cluster-advertise=eth1:2376" $VM_1 
docker-machine create -d virtualbox --swarm --swarm-discovery="consul://$DS_IP:8500" --engine-opt="cluster-store=consul://$DS_IP:8500" --engine-opt="cluster-advertise=eth1:0" $VM_2


#set overlayer network and run nginx
eval $(docker-machine env --swarm $VM_1)
docker network create --subnet=$NETWORK -d overlay $NETWORK_NAME 
docker build -t ng --build-arg CONSUL=$(docker-machine ip $DS_VM) ./nginx/
./nginx_generator.sh -vm $VM_1 -ds $DS_IP -name "$PROXY" 

#run log container
eval $(docker-machine env $VM_2)
docker build -t $LOG_IMAGE ./Logs/
./logstash_generator.sh -vm $VM_2 -ds $DS_IP -name "$LOG_INSTANCE" -image "$LOG_IMAGE"

#run rails webapps

sleep 15
#initialize empty dynamo k-v storage in consul
curl -X PUT -H "Content-Type: application/json" -d '{}' http://$DS_IP:8500/v1/kv/docker_nodes

docker build -t $RAILS_NODE_IMAGE ./rails-node-app/
./rails_app_gener.sh -vm $VM_2 -ds $DS_IP -name "$RAILS_NODE" -image "$RAILS_NODE_IMAGE" -r "$REPLICATION" -d $DYN_MAX_KEY
./rails_app_gener.sh -vm $VM_2 -ds $DS_IP -name "$RAILS_NODE" -image "$RAILS_NODE_IMAGE" -r "$REPLICATION" -d $DYN_MAX_KEY
./rails_app_gener.sh -vm $VM_2 -ds $DS_IP -name "$RAILS_NODE" -image "$RAILS_NODE_IMAGE" -r "$REPLICATION" -d $DYN_MAX_KEY

