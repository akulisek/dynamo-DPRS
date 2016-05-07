class IPService

  require 'socket'

  def self.local_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end

  def self.get_request uri
    url = URI.parse(uri)
    request = Net::HTTP::Get.new(url.to_s)
    response = Net::HTTP.start(url.host, url.port) {|http|
      http.request(request)
    }
    response
  end

  def self.post_request uri
    uri = URI.parse(uri)
    headers = {'Content-Type' => "application/json", 'Accept-Encoding'=> "gzip,deflate"}
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.basic_auth(options[:user], options[:password])
    request.body = data.to_json
    response = http.request(request)
  end

  def self.append_node_to_key_value

  end

end