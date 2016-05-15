#!/usr/bin/env ruby
# script responsible for removing dead dynamo nodes from config KV in consul

require 'json'
require 'net/http'

IO.write('/tmp/watches.log', "config_updater called\n", mode: 'a')

input = STDIN.read
IO.write('/tmp/watches.log', "input:"+input+"\n", mode: 'a')
if !input || input.empty?
	exit 0
end

#json array
current_services = JSON.parse(input)

#parse service ip adresses from current_services
current_ips = {}
current_services.each do |service|
	ip = service["Service"]["Address"].partition(':')[0]
	current_ips[ip] = true
end
IO.write('/tmp/watches.log', "parsed current ips:\n"+current_ips.keys.join(", ")+"\n", mode: 'a')

#get current config
url = 'http://localhost:8500/v1/kv/docker_nodes?raw'
uri = URI.parse(url)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)

if !response.body || response.body.empty? || response.body.length == 0
	#empty config, nothing to do
	exit 0
end

dynamo_nodes = JSON.parse(response.body)
IO.write('/tmp/watches.log', "current config:\n"+dynamo_nodes+"\n", mode: 'a')

#iterate over config, removing nodes that are not in current_ips
nodes_removed = 0;
dynamo_nodes.delete_if do |ip_port,data|
	ip = ip_port.partition(':')[0]
	if !(current_ips.key?(ip))
		nodes_removed+=1;
		true
	else
		false
	end
end
IO.write('/tmp/watches.log', "removed:"+nodes_removed+" nodes\n", mode: 'a')
IO.write('/tmp/watches.log', "new config:\n"+dynamo_nodes+"\n", mode: 'a')

# only update config if at least one node was removed (KV watch would be triggered if we post same config)
if nodes_removed > 0
	url = 'http://localhost:8500/v1/kv/docker_nodes'	
	uri = URI.parse(url)
	headers = {'Content-Type' => 'application/json', 'Accept-Encoding'=> 'gzip,deflate'}
	http = Net::HTTP.new(uri.host, uri.port)
	request = Net::HTTP::Put.new(uri.request_uri, headers)
	request.body = JSON.parse(dynamo_nodes.to_json).to_json
	http.request(request)
end
