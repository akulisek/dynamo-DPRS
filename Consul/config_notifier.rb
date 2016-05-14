#!/usr/bin/env ruby
# script responsible for broadcasting config change notification to dynamo nodes

require 'json'
require 'net/http'
<<<<<<< 7331329211d5677fc6d239c56cfe31bc198eb649
require 'base64'
                                     
encoded_conf = JSON.parse(STDIN.read)         
dynamo_nodes = Base64.decode64(encoded_conf["Value"])
=======

dynamo_nodes = JSON.parse(STDIN.read)
>>>>>>> Change watch scripts EOL to UNIX

dynamo_nodes.each do |ip_port,data|
	url = 'http://'+ip_port+'/node/update_configuration'
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	request = Net::HTTP::Get.new(uri.request_uri)
	response = http.request(request)
end
