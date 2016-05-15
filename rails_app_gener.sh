#/bin/bash

#################################
# configuration variables
################################

# default parameters

NETWORK_NAME="private-network"
NETWORK="192.168.0.0/24"
RAILS_NODE="rails-webapp"
RAILS_NODE_IMAGE="rails-image"
REPLICATION="3"
DYN_MAX_KEY="65536"

# arguments

while [ "$2" != "" ]; do
    PARAM="$1";
    VALUE="$2";
    case $PARAM in
	-n)     
		$NETWORK="$VALUE"
		exit
	-nName) 
		$NETWORK_NAME="$VALUE" 
		exit
	-name)
		$RAILS_NODE="$VALUE"
		exit
	-image)
		$RAILS_NODE_IMAGE="$VALUE"
		exit
	-r)
		$REPLICATION="$VALUE"
		exit
	-d) 
		$DYN_MAX_KEY="$VALUE"
	*)
            echo "Nezrozumitelny parameter \"$PARAM\""
            exit 1 #exit on this
    esac	
    shift
    shift
done

#############################################
# creating app
#############################################

echo "---------Creating rails app---------";





source test2.sh -d "nie"
