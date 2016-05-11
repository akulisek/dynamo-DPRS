class HTTPService

  require 'net/http'

  def self.get_request path
    uri = URI.parse(path)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    http.request(request)
  end

  def self.post_request path, body
    uri = URI.parse(path)
    headers = {'Content-Type' => 'application/json', 'Accept-Encoding'=> 'gzip,deflate'}
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = JSON.parse(body)
    http.request(request)
  end

  def self.put_request path, body
    uri = URI.parse(path)
    headers = {'Content-Type' => 'application/json', 'Accept-Encoding'=> 'gzip,deflate'}
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri, headers)
    request.body = JSON.parse(body.to_json).to_json
    http.request(request)
  end

end