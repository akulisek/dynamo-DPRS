#bin/bash

while [ 1 == 1 ]; do
	DELETED=0;
	DELETED_NODES="";
	SERVICES=$(curl http://localhost:8500/v1/health/state/critical)


	NODES=$(echo $SERVICES | tr ',' '\n'|grep service| cut -d ":" -f3)
	echo $NODES
	if [ "$NODES" == "" ]; then
		echo "no servise to delete"		
	else
		for node in $NODES; do
		for deleted_node in $OLD_NODES; do
			if [ "$deleted_node" == "$node" ]; then	
				temp=$(echo $deleted_node| tr -d '"')
				DELETED_NODES="$DELETED_NODES $temp"
			fi
		done 
		done

		OLD_NODES=$NODES

		echo "--------Deleting nodes--------------"
		for node in $DELETED_NODES; do 
			curl -X PUT http://localhost:8500/v1/agent/service/deregister/$node
			echo "service $node deleted"
			DELETED=1;
		done
		if [ $DELETED == 1 ]; then
			DELETED_NODES="";
			DELETED=0;
		fi
	fi
	sleep 15; 
done
