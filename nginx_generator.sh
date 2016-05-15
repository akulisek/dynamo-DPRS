#/bin/bash

#################################
# configuration variables
################################

# default parameters

PROXY="proxy"
VM_1="null"
NETWORK_NAME="private-network"
NETWORK="192.168.0.0/24"

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

		PROXY="$VALUE"
		;;
	-image)

		RAILS_NODE_IMAGE="$VALUE"
		;;
	-vm)
		VM_1="$VALUE"
		;;
	-ds)
		DS_IP="$VALUE"
		;;
    esac	
    shift
done

#############################################
# creating nginx
#############################################

ID_CONTAINER=$[RANDOM % 10 + 1]
UUID=$(cat /proc/sys/kernel/random/uuid)
IP=$(docker-machine ip $VM_2)

docker run -itd -p 80:80 --name=$PROXY$ID_CONTAINER --net=$NETWORK_NAME --env="constraint:node==$VM_1" ng

json="{ \"ID\": \"$UUID\", \"Name\": \"$PROXY\", \"Address\": \"$IP\", \"Port\": 80, \"check\": { \"name\": \"web-check\",  \"http\": \"http://$IP:80\", \"interval\": \"20s\", \"timeout\": \"5s\", \"status\": \"passing\"}}"

echo $json > ./temporary.json
curl -X PUT --data-binary @temporary.json http://$DS_IP:8500/v1/agent/service/register
rm ./temporary.json


