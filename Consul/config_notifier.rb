#!/usr/bin/env ruby
# script responsible for broadcasting config change notification to dynamo nodes

require 'json'
require 'net/http'
require 'base64'

IO.write('/tmp/watches.log', "config_notifier called\n", mode: 'a')

input = STDIN.read
IO.write('/tmp/watches.log', "input:"+input+"\n", mode: 'a') 
if (!input) || (input.empty?) || input.length == 0 || input.start_with?('null')
	#empty config, noone to notify	
	exit 0
end
                                 
encoded_conf = JSON.parse(input)
IO.write('/tmp/watches.log', "encoded_conf:\n"+encoded_conf.to_json+"\n", mode: 'a')         
dynamo_nodes = JSON.parse(Base64.decode64(encoded_conf["Value"]))
IO.write('/tmp/watches.log', "decoded json:\n"+dynamo_nodes.to_json+"\n", mode: 'a') 

dynamo_nodes.each do |ip_port,data|
	url = 'http://'+ip_port+'/node/update_configuration'
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	request = Net::HTTP::Get.new(uri.request_uri)
	IO.write('/tmp/watches.log', "Get: "+url+"\n", mode: 'a')
	response = http.request(request)
end
