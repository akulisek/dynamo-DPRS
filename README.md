# Dynamo
Repository for FIIT STU class - DPRS project

## Progress
### 22.3
We've been able to create a multi-host network consisting of 3 docker-machines, each running several containers. So far we have used Consul, Registrator, Docker Swarm and NGINX.
Containers can communicate with each other (only ping atm) across VMs. 

### 23.3
Added init script whitch start machines, plus modified Dockerfile for nodes

TODO:  
-use Consul-Template for updating proxy config when new container joins (or leaves) the network.  
-create dummy applications that will be run on DataNodes with simple REST APIs.  

### 27.3
Init and Uninstall script polished andissues with java_image containers (registrator ignored them) fixed.
Dummy Java applications have been created under node-app folder. 

TODO and IN_PROGRESS:  
-Consul-Template integration (proxy conf update in consul).  
-rsyslog / ELK stack integration.  
