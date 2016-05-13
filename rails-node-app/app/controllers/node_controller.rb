class NodeController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:read_key_value, :write_key_value, :update_configuration]
  before_action :update_configuration_before_registration, :only => [:register_to_service_discovery]

  @@key_value_storage = {}
  @@dynamo_nodes = {}
  @@my_key = nil

  @@initialized = false

  def index
    puts 'NodeController#index ' + Rails.env
    logger.warn 'Hello from NodeController!, my key is ' + @@my_key.to_s
    logger.warn 'Dynamo nodes: ' + @@dynamo_nodes.to_s
  end

  def read_key_value
    if can_serve_request?(params[:key])
      log_message('Reading key:'+params[:key])
      response = @@key_value_storage[params[:key]]
    else
      log_message('Redirecting GET request')
      response = JSON.parse(designate_coordinator(:get))
      log_message('Response from coordinator: ' + response.to_s + ' with class: ' + response.class.to_s)
      response = response['response']
    end
    respond_to do |format|
      format.json { render :json => { :response => response } }
    end
  end

  def write_key_value
    if can_serve_request?(params[:key])
      log_message('Writing key:' + params[:key] + ' with value:' + params[:value])
      store_value(params[:key], params[:value])
      response = @@key_value_storage[params[:key]] || 'Storing value failed'
    else
      log_message('Redirecting POST request')
      response = JSON.parse(designate_coordinator(:post))
      log_message('Response from coordinator: ' + response.to_s + ' with class: ' + response.class.to_s)
      response = response['response']
    end
    respond_to do |format|
      format.json { render :json => { :response => response } }
    end
  end

  # consul broadcasts all nodes with GET request to this upon /v1/kv/docker_nodes change
  def update_configuration
    url = 'http://'+ENV['CONSUL_IP']+':8500/v1/kv/docker_nodes?raw'
    log_message('Updating configuration from: ' + url)
    response = HTTPService.get_request(url)
    log_message(response.body)
    @@dynamo_nodes = JSON.parse(response.body)
    respond_to do |format|
      format.json { render :json => { :configuration => @@dynamo_nodes } }
    end
  end

  def register_to_service_discovery
    unless @@initialized
      pick_random_key
      @@dynamo_nodes[ENV['CONTAINER_ADDRESS']] = { :hash_key => @@my_key, :container_id => ENV['HOSTNAME'] }
      url = 'http://'+ENV['CONSUL_IP']+':8500/v1/kv/docker_nodes'
      HTTPService.put_request(url, @@dynamo_nodes)
      @@initialized = true
    end
    respond_to do |format|
      format.json { render :json => { :initialized => @@initialized } }
    end
  end

  def get_data

  end

  private

  def update_configuration_before_registration
    url = 'http://'+ENV['CONSUL_IP']+':8500/v1/kv/docker_nodes?raw'
    log_message('Updating configuration from: ' + url)
    response = HTTPService.get_request(url)
    log_message(response.body)
    @@dynamo_nodes = JSON.parse(response.body)
  end

  def store_value key, value
    @@key_value_storage[key] ||= value if key
  end

  def coordinate_request

  end

  def designate_coordinator type
    nodes = get_responsible_nodes(params[:key])
    rand_index = SecureRandom.random_number(3)
    log_message('Designating coordinator for nodes: ' + nodes.size.to_s + ' and type: ' + (type == :get).to_s )
    nodes.each_with_index do |(key, value),index|
      if index == rand_index
        if type == :get
          puts 'Redirecting request to:' + 'http://' + key + '/node/read_key?&key=' + params[:key]
          log_message('Redirecting request to:' + 'http://' + key + '/node/read_key?&key=' + params[:key])
          response = HTTPService.get_request('http://' + key + '/node/read_key?&key=' + params[:key])
          puts 'Response body:' + response.body.to_s
          log_message('Response body:' + response.body.to_s)
          return response.body
        elsif type == :post
          puts 'Redirecting request to:' + 'http://' + key + '/node/write_key with data: ' + { :key => params[:key], :value => params[:value]}.to_s
          log_message('Redirecting request to:' + 'http://' + key + '/node/write_key with data: ' + { :key => params[:key], :value => params[:value]}.to_s)
          response = HTTPService.post_request('http://' + key + '/node/write_key', { :key => params[:key], :value => params[:value]})
          puts 'Response body:' + response.body.to_s
          log_message('Response body:' + response.body.to_s)
          return response.body
        end
      end
    end
  end

  def can_serve_request? key
    get_responsible_nodes(key).any? do |_k, v|
      log_message('comparing ' + v.first.second + ' to ' + @@my_key)
      v.first.second == @@my_key
    end
  end

  def get_responsible_nodes key
    responsible_hash_keys = []
    if @@dynamo_nodes.size <= 3
      return @@dynamo_nodes
    end
    responsible_node_key = 0
    previous = 0

    sorted_hash_keys = @@dynamo_nodes.sort_by { |_k,v| v.first.second.to_i}.map {|_k,v| v.first.second}

    sorted_hash_keys.each do |hash_key|
      #log_message('Comparing key '+key.to_i.to_s+' to hash_key '+hash_key.to_i.to_s)
      if key.to_i.between?(previous.to_i,hash_key.to_i)
        responsible_node_key = hash_key
        break
      elsif hash_key.to_i == sorted_hash_keys.last.to_i && hash_key.to_i < key.to_i
        responsible_node_key = sorted_hash_keys.first
      else
        previous = hash_key
      end
    end

    sorted_hash_keys.each_with_index do |key, index|
      if key == responsible_node_key
        3.times.each_with_index { |_e, iterator| responsible_hash_keys << sorted_hash_keys[(index + iterator) % sorted_hash_keys.size]}
      end
    end

    @@dynamo_nodes.select { |_k, v| v.first.second.in?(responsible_hash_keys) }

  end

  # generate such key that no pair of nodes are responsible for 100 or less keys
  def pick_random_key
    satisfied = false
    keys = @@dynamo_nodes.map { |_k,v| v['hash_key']}.sort
    while !satisfied do
      generated_key = SecureRandom.random_number(ENV['DYNAMO_MAX_KEY'].to_i)
      collision = false
      keys.each do |key|
       if (key.to_i - generated_key).abs <= 100
         collision = true
         break
       end
      end
      satisfied = !collision
    end
    @@my_key = generated_key.to_s
  end

  def log_message message
    logger.warn 'REQUEST ' + params[:correlation_id].to_s + ' :: CONTAINER ' + ENV['HOSTNAME'] + ' :: ' + message
  end

end
