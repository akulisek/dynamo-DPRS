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





