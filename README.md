# Dynamo
Repository for FIIT STU class - DPRS project

## Progress
### 22.3
We've been able to create a multi-host network consisting of 3 docker-machines, each running several containers. So far we have used Consul, Registrator, Docker Swarm and NGINX.
Containers can communicate with each other (only ping atm) across VMs. 

### 23.3
Added init script which starts docker-machines and added modified Dockerfile for nodes

TODO:  
-use Consul-Template for updating proxy config when new container joins (or leaves) the network.  
-create dummy applications that will be run on DataNodes with simple REST APIs.  

### 27.3
Init and Uninstall script polished andissues with java_image containers (registrator ignored them) fixed.
Dummy Java applications have been created under node-app folder. 

TODO and IN_PROGRESS:  
-Consul-Template integration (proxy conf update in consul).  
-rsyslog / ELK stack integration.  

### 28.3
Consul-Template has been successfully integrated and proxy config updates work automatically. We have come across some problems with  (registrator assigned localhost IP => containers were unreachable) - we had to use other Registrator image that could perform well with overlay network. We are currently having some issues with rsyslog init scripts, kibana and logstash should be linked together soon.

IN_PROGRESS:  
-rsyslog / ELK stack integration.  

TODO:
Dynamo
