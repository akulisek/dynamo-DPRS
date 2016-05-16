#!/usr/bin/env ruby
# script responsible for broadcasting config change notification to dynamo nodes

require 'json'
require 'net/http'

IO.write('/tmp/watches.log', "config_notifier called\n", mode: 'a')

#read stdin, unused
input = STDIN.read

#http://localhost:8500/v1/catalog/service/rails-webapp
url = 'http://localhost:8500/v1/catalog/service/rails-webapp'
uri = URI.parse(url)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)
IO.write('/tmp/watches.log', "Response: "+response.body+"\n", mode: 'a')

services = JSON.parse(response.body)
services.each do |service|
	output = service["ServiceTags"]
	if output.empty?
			next
	end
	ip_port = output.first
	if ip_port.include? ":"
		#contact..
		url = 'http://'+ip_port.to_s+'/node/update_configuration'
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Get.new(uri.request_uri)
		IO.write('/tmp/watches.log', "Get: "+url+"\n", mode: 'a')
		response = http.request(request)
	end
end
