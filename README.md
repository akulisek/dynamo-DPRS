# Dynamo
Repository for FIIT STU class (DPRS) project

## Used technologies

<p align="center">
  <a href="https://www.consul.io/">
    <img src="http://cdn.rancher.com/wp-content/uploads/2016/03/11015408/consul-logo-square-100x100.png" alt="Consul"/>
  </a>
<br>
  <a href="https://www.nginx.com/resources/wiki/">
    <img src="https://community.logentries.com/wp-content/uploads/2014/11/nginx-pack-icon.png" alt="NGINX"/>
  </a>
  <a href="https://www.elastic.co/webinars/introduction-elk-stack">
    <img src="https://raw.githubusercontent.com/blacktop/docker-elk/master/docs/elk-logo.png" alt="ELK stack"/>
  </a>
</p>

## Setting up the project
After downloading this repo to a folder you have to run `$ bash init` which will initialize all the necessary docker machines and containers for you.

### Find out about your IPs
* NGinx (proxy): `$ docker-machine ip sm-docker-0`
* Consul (service discovery): `$ docker-machine ip docker-SD`
* Kibana (dashboard): `$ docker-machine ip docker-LOG`

### Acess Kibana UI and Consul UI
* Kibana: http://Kibana_IP:8080
* Consul: http://Consul_IP:8500

## Letting go
If you wish to remove the whole project from your machine feel free to `$ bash uninstall`. This will remove all the docker machines we have created for you with the `init` script automatically.

## Removing containers
If you want to keep the machines and remove all the containers `init` has run without screwing up the swarm, feel free to run `$ bash remove_containers` and it will do the trick for you.

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
Init and Uninstall script polished and issues with java_image containers (registrator ignored them) fixed.
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

### 29.3
We have successfully finished integrating ELK stack into our system. Logs are being centralized, Kibana is set up (displays logs), we have created single REST API method ($PROXY_IP/dynamo-node-webapp/dynamo/hello/$USER_INPUT) which responds with "Hello $USER_INPUT!" from one of the java app containers. We use Consul's key-value store only for storing logserver's IP atm.

TODO:
Dynamo

### 12.5
We have decided to switch from Java framework to Ruby on Rails (DynamoDB nodes). We have managed to implement consistent hashing (95% done) and currently we are working on read-write quorum, vector clocks and container metrics, service discovery broadcasts and additional SD configuration. 

TODO:
quorum
vector clocks
metrics (zabbix?)
ELK graphs
Consul broadcasts
