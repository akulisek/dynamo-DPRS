# Dynamo
Class (Distributed program systems) project - clone of DynamoDB created at FIIT STU

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
  <a href="https://rubyonrails.org">
    <img src="http://rubyonrails.org/images/rails-logo.svg" alt="Ruby on Rails" width="242"/>
  </a>
</p>

## Setting up the project
Run `$ bash init.sh` to initialize all the necessary docker machines and containers. Our DynamoDB consists of 3 Ruby on Rails nodes by default. We strongly advise you to maintain at least 3 nodes in your system configuration as we have not considered DynamoDB to work in other circumstances for the purposes of the project.

### Find out about your IPs
* NGinx (proxy): `$ docker-machine ip sm-docker-0`
* Consul (service discovery): `$ docker-machine ip docker-SD`
* Kibana (dashboard): `$ docker-machine ip docker-LOG`

### Acess Kibana UI and Consul UI
* Kibana: http://kibana_ip:8080
* Consul: http://consul_ip:8500

## Letting go
If you wish to remove the whole project from your machine feel free to `$ bash uninstall`. This will remove all the docker machines we have created for you with the `init` script automatically.

## Adding DynamoDB container
If you want to add another RoR container for your DynamoDB, run `$ bash rails_app_gener.sh -vm $VM_NAME -ds $CONSUL_IP`. VM_NAME should be a valid docker-machine name of the machine you want to run the container on and $CONSUL_IP should be an IP address of the machine that runs service discovery.

## Removing DynamoDB containers
If you want to keep the machines and remove all the DynamoDB containers created by `init` or you without screwing up the swarm, execute `$ bash remove_dynamo_containers` and it will do the trick for you.

## GUI
You can acess the GUI at http://`$ docker-machine ip sm-docker-0`/. You can read and write values for a specific hash key. You don't need to specify vector clock when writing value for a key for the first time, although you can (given that you have already read that key and DynamoDB returned initial vector clock). On the other hand, you have to provide vector clock when storing value for a key that you have already stored some value for, otherwise DynamoDB will assign new vector clock for that value (DynamoDB treats the value as a completely new version of the object).  
This is what the GUI looks like:  
![alt tag](https://github.com/akulisek/Dynamo/blob/origin/modified-consul/GUI-screenshot.png)


## API
There are two main functions of the DynamoDB: read and write data.
### Read values for given key
GET `http://proxy_ip/node/read_key?&key=12345` for reading values of key = 12345. 
If you wish to specify read quorum add another parameter: `http://proxy_ip/node/read_key?&key=12345&read_quorum=2`
### Store values for given key
POST `http://proxy_ip/node/write_key` and specify needed request parameters:  
`{  
    "key":"113",  
    "value":"random_value"  
}`  
There are some optional parameters:  
`   
    "write_quorum":"2",  
    "vector_clock":{  
    "68535db237f3=1;a36909a4384f=1;f1f28dd2e53a=0;": {  
      "68535db237f3": "1",  
      "value": "some_random_stored_value",  
      "f1f28dd2e53a": "0",  
      "a36909a4384f": "1"  
    }  
    }  
`    
Vector clock can be acquired by calling `read_key` API method for a key that has stored data.  

If you wish to specify read quorum add another parameter: `http://proxy_ip/node/read_key?&key=12345&read_quorum=2`  

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

### 14.5
Implemented quorum and replication of hash keys across nodes. Whenever node fails / new one registers to network, others acclimatize. New node first gets all the data he will be responsible for after registering to network and afterwards finally joins the network. Consul registers a change of DynamoDB configuration in it's key-value storage and broadcasts all nodes. They then update their data, replicate what is new, delete what is old and not needed of them anymore and adjust to changes. If quorum requirements coudln't be satisfied user gets notified.

TODO:  
vector clocks  
metrics (zabbix?)  
ELK graphs  

### 15.5
Vector clocks have been successfully implemented. Casualities are dealt with automatically (Hash table datastructure helps). Broadcasts are being tested and so are health checks. The only thing left undone is GUI interface for better UX. That will be implemented tomorrow along with some basic graphs in ELK.

TODO:  
metrics (zabbix?)  
ELK graphs  
GUI  

### 16.5
We can finally say that we have successfully implemented DynamoDB with all it's key features: consistent hashing, vector clocks, replication and fault tolerance. The only few things left undone are integration of monitoring platform (Zabbix for example) and advanced ELK graphs for better visualization of system activity.

TODO:  
metrics (zabbix?)  
