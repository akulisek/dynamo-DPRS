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

		LOG_INSTANCE="$VALUE"
		;;
	-image)

		LOG_IMAGE="$VALUE"
		;;
	-vm)
		LOG_VM="$VALUE"
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
UUID=$(uuidgen)
LOG_IP=$(docker-machine ip $LOG_VM)

docker run -itd -p 8080:80 -p 5000:5000 -p 5000:5000/udp --net=$NETWORK_NAME --name "$LOG_INSTANCE$ID_CONTAINER" --env="constraint:node==$LOG_VM" -e CONSUL_IP=$DS_IP -e LOG_HOST_IP=$LOG_IP $LOG_IMAGE

json="{ \"ID\": \"$UUID\", \"Name\": \"$LOG_INSTANCE\", \"Address\": \"$LOG_IP\", \"Port\": 8080, \"check\": { \"name\": \"web-log\",  \"http\": \"http://$LOG_IP:8080\", \"interval\": \"10s\", \"timeout\": \"5s\", \"status\": \"passing\"}}"

echo $json > ./temporary.json
curl -X PUT --data-binary @temporary.json http://$DS_IP:8500/v1/agent/service/register
rm ./temporary.json
