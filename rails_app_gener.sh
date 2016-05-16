#/bin/bash

#################################
# configuration variables
################################

# default parameters

VM_2="null"
DS_IP="null"
NETWORK_NAME="private-network"
NETWORK="192.168.0.0/24"
RAILS_NODE="rails-webapp"
RAILS_NODE_IMAGE="rails-image"
REPLICATION="3"
DYN_MAX_KEY="65536"

# arguments
while (( "$#" ));
do
    PARAM="$1";
    VALUE="$2";
    case $PARAM in
	-n)     
		NETWORK="$VALUE"
		;;
	-nName) 
		NETWORK_NAME="$VALUE" 
		;;
	-name)

		RAILS_NODE="$VALUE"
		;;
	-image)

		RAILS_NODE_IMAGE="$VALUE"
		;;
	-r)
		REPLICATION="$VALUE"
		;;
	-d) 
		DYN_MAX_KEY="$VALUE"
		;;
	-vm)
		VM_2="$VALUE"
		;;
	-ds)
		DS_IP="$VALUE"
		;;
    esac	
    shift
done

#############################################
# creating app
#############################################

echo "---------Creating rails app---------";
echo "Parameters:"
echo $VM_2
echo $DS_IP
echo $NETWORK_NAME
echo $NETWORK
echo $RAILS_NODE
echo $RAILS_NODE_IMAGE
echo $REPLICATION
echo $DYN_MAX_KEY

echo "---------Creating rails app---------"

PORT=$[RANDOM % 64530 + 1024]
ID_CONTAINER=$[RANDOM % 1000 + 1]
UUID=$(uuidgen)
IP=$(docker-machine ip $VM_2)

json="{ \"ID\": \"$UUID\", \"Name\": \"$RAILS_NODE\", \"Address\": \"$OVER_IP\", \"Port\": 3000, \"check\": { \"name\": \"web-check\",  \"http\": \"http://$IP:$PORT\", \"interval\": \"20s\", \"timeout\": \"5s\", \"status\": \"passing\"}}"

echo $json

docker run -itd -p $PORT:3000 --net="$NETWORK_NAME" --name "$RAILS_NODE$ID_CONTAINER" --env="constraint:node==$VM_2" -e CONSUL_IP=$DS_IP -e REPLICATION=$REPLICATION -e DYNAMO_MAX_KEY=$DYN_MAX_KEY -e REGISTER_STRING="$json" $RAILS_NODE_IMAGE 

##############
# temporary
##############

OVER_IP=$(docker exec  $RAILS_NODE$ID_CONTAINER ip addr| grep "inet "| grep "192.168"| tr -s "/" |cut -d "/" -f1|tr -s " "|cut -d " " -f3)

json="{ \"ID\": \"$UUID\", \"Name\": \"$RAILS_NODE\", \"Address\": \"$OVER_IP\", \"Port\": 3000, \"check\": { \"name\": \"web-check\",  \"http\": \"http://$IP:$PORT\", \"interval\": \"10s\", \"timeout\": \"5s\", \"status\": \"passing\"}}"

sleep 15

echo $json > ./temporary.json
curl -X PUT --data-binary @temporary.json http://$DS_IP:8500/v1/agent/service/register
rm ./temporary.json

curl http://$(docker-machine ip $VM_2):$(docker ps | grep "$RAILS_NODE_$ID_CONTAINER" | tr -s " " | cut -d" " -f16 | cut -d: -f2 | cut -d"-" -f1)/node/register_to_service_discovery



