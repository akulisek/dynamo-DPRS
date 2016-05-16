#!/usr/bin/env ruby
# script responsible for broadcasting config change notification to dynamo nodes

require 'json'
require 'net/http'

IO.write('/tmp/watches.log', "config_notifier called\n", mode: 'a')

#read stdin, unused
input = STDIN.read

#read passing dynamo node checks (alive nodes) to get vm ip:port XXX .. http://localhost:8500/v1/health/service/rails-webapp?passing
url = 'http://localhost:8500/v1/health/service/rails-webapp?passing'
uri = URI.parse(url)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)
IO.write('/tmp/watches.log', "Response: "+response.body+"\n", mode: 'a')

checks = JSON.parse(response.body)
checks.each do |check|
#parse ip:port from check response - "Output":"HTTP GET http://192.168.99.102:19305: 200 OK
	output = check["Checks"][0]["Output"]
	if output.empty? || !(output.start_with?('HTTP GET'))
			next
	end
	ip_port = output.split(' ')[2][0..-2]
	if ip_port.start_with?('http')
		#contact..
		url = ip_port+'/node/update_configuration'
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Get.new(uri.request_uri)
		IO.write('/tmp/watches.log', "Get: "+url+"\n", mode: 'a')
		response = http.request(request)
	end
end
