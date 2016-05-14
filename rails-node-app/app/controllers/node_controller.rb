class NodeController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:read_key_value, :write_key_value, :update_configuration]
  before_action :update_configuration_before_registration, :only => [:register_to_service_discovery]

  @@key_value_storage = {}
  @@dynamo_nodes = {}
  @@my_key = nil

  @@initialized = false

  def index
    logger.warn 'NodeController#index ' + Rails.env
    logger.warn 'Hello from NodeController!, my key is ' + @@my_key.to_s
    logger.warn 'Dynamo nodes: ' + @@dynamo_nodes.to_s
  end

  def read_key_value
    if can_serve_request?(params[:key])
      if params[:coordinated]
        log_message('Reading key, request is coordinated:'+params[:key])
        response = @@key_value_storage[params[:key]]
      else
        log_message('Coordinating read key:'+params[:key])
        accept_counter = 0
        read_quorum = params[:read_quorum].to_i || 0 #parse_quorum_json(params[:quorum], :read)

        response = []
        responses = coordinate_request(:get)
        log_message('Coordinated response: ' + responses.to_s )
        responses.each { |r| accept_counter +=1 unless r.nil?; response << r unless r.nil?}

        unless accept_counter >= read_quorum
          response = 'Sorry, request quorum was not satisfied by DynamoDB'
        end
      end
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
      if params[:coordinated]
        log_message('Writing key, request is coordinated::' + params[:key] + ' with value:' + params[:value])
        store_value(params[:key], params[:value])
        response = @@key_value_storage[params[:key]] || 'Storing value failed'
      else
        log_message('Coordinating write key:'+params[:key])
        accept_counter = 0
        write_quorum = params[:write_quorum].to_i || 0 #parse_quorum_json(params[:quorum], :write)

        response = []
        responses = coordinate_request(:post)
        responses.each { |r| accept_counter +=1 unless r.nil?; response << r unless r.nil?}

        unless accept_counter >= write_quorum
          response = 'Sorry, request quorum was not satisfied by DynamoDB'
        end
      end
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
    if @@initialized
      url = 'http://'+ENV['CONSUL_IP']+':8500/v1/kv/docker_nodes?raw'
      #log_message('Updating configuration from: ' + url)
      response = HTTPService.get_request(url)
      log_message('Dynamo changed, updating configuration to: ' + response.body)
      response = JSON.parse(response.body)
      replicate_data(response)
    end
    respond_to do |format|
      format.json { render :json => { :configuration => @@dynamo_nodes } }
    end
  end

  def register_to_service_discovery
    unless @@initialized
      pick_random_key
      replicate_data_before_registration
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
    data = select_my_key_data
    respond_to do |format|
      format.json { render :json => { :response => data } }
    end
  end

  def get_all_data
    respond_to do |format|
      format.json { render :json => { :response => @@key_value_storage } }
    end
  end

  def get_data_for_range
    data = select_data_for_range(params[:from], params[:to])
    respond_to do |format|
      format.json { render :json => { :response => data } }
    end
  end

  private

  def replicate_data new_config
    old_sorted_hash_keys = @@dynamo_nodes.sort_by { |_k,v| v.first.second.to_i}.map {|_k,v| v.first.second}
    new_sorted_hash_keys = new_config.sort_by { |_k,v| v.first.second.to_i}.map {|_k,v| v.first.second}

    hash_old = Hash[old_sorted_hash_keys.map.with_index.to_a]
    hash_new = Hash[new_sorted_hash_keys.map.with_index.to_a]

    if new_config.size < @@dynamo_nodes.size
      removed_node = old_sorted_hash_keys.select { |e| !e.in?(new_sorted_hash_keys) }.first
      log_message('Container with key: ' + removed_node.to_s + ' was removed from dynamo')

      removed_after_myself = (new_sorted_hash_keys[(hash_new[@@my_key] + 2) % hash_new.size] != old_sorted_hash_keys[(hash_old[@@my_key] + 2) % hash_old.size] )
      removed_before_myself = (new_sorted_hash_keys[(hash_new[@@my_key] - 1) % hash_new.size] != old_sorted_hash_keys[(hash_old[@@my_key] - 2) % hash_old.size] )

      uri = nil
      if removed_after_myself
        log_message('Container was removed after me and I have to get new data from: ' +
                        old_sorted_hash_keys[(hash_old[@@my_key] + 2) % hash_old.size] +
                        ' to:' + new_sorted_hash_keys[(hash_new[@@my_key] + 2) % hash_new.size])

        node = new_config.select { |ip, data| data.first.second == new_sorted_hash_keys[(hash_new[@@my_key] + 2) % hash_new.size] }
        uri = 'http://' + node.first.first +
            '/node/get_data_for_range?&from=' +
            old_sorted_hash_keys[(hash_old[@@my_key] + 2) % hash_old.size] +
            '&to=' + new_sorted_hash_keys[(hash_new[@@my_key] + 2) % hash_new.size]
      elsif removed_before_myself
        log_message('Container was removed right before me and I have to get new data from: ' +
                        new_sorted_hash_keys[(hash_new[@@my_key] + -1) % hash_new.size] +
                        ' to:' + old_sorted_hash_keys[(hash_old[@@my_key] - 2) % hash_old.size])

        node = new_config.select { |ip, data| data.first.second == new_sorted_hash_keys[(hash_new[@@my_key] + -1) % hash_new.size] }
        uri = 'http://' + node.first.first +
            '/node/get_data_for_range?&from=' +
            new_sorted_hash_keys[(hash_new[@@my_key] + -1) % hash_new.size] +
            '&to=' + old_sorted_hash_keys[(hash_old[@@my_key] - 2) % hash_old.size]
      end
      if uri
        log_message('Getting new data after removing a contaniner from: ' + uri)
        response = JSON.parse(HTTPService.get_request(uri).body)['response']
        response.each do |key, value|
          store_value(key, value)
        end
      end
    elsif new_config.size > @@dynamo_nodes.size
      inserted_node = new_sorted_hash_keys.select { |e| !e.in?(old_sorted_hash_keys) }.first
      log_message('Container with key: ' + inserted_node.to_s + ' was inserted to dynamo')

      index_range_after = []
      index_range_before = []
      3.times.each_with_index { |_e, iterator| index_range_after << ((hash_new[@@my_key] + iterator) % hash_new.size ) }
      index_range_before << ((hash_new[@@my_key] - 1) % hash_new.size )

      inserted_after_myself = hash_new[inserted_node].in?(index_range_after)
      inserted_before_myself = hash_new[inserted_node].in?(index_range_before)
      log_message('Index range before: ' + index_range_before.to_s + ' ; Index range after: ' + index_range_after.to_s +
                      ' ; Inserted: ' + hash_new[inserted_node].to_s + 'Inserted node: ' + inserted_node.to_s +
                      ' ; Inserted_after_myself: ' + inserted_after_myself.to_s +
                      ' ; Inserted_before_myself: ' + inserted_before_myself.to_s
      )


      hash_range_to_delete = []
      if inserted_before_myself
        log_message('Container was added before me and I remove values with range from: ' +
                        new_sorted_hash_keys[(hash_new[inserted_node] - 1) % hash_new.size] +
                        ' to: ' + new_sorted_hash_keys[hash_new[inserted_node]])
        hash_range_to_delete << new_sorted_hash_keys[(hash_new[inserted_node] - 1) % hash_new.size].to_i
        hash_range_to_delete << new_sorted_hash_keys[hash_new[inserted_node]].to_i
      elsif inserted_after_myself
        log_message('Container was added after me and I remove values with range from: ' +
                        new_sorted_hash_keys[(hash_new[@@my_key] + 2) % hash_new.size] +
                        ' to: ' + old_sorted_hash_keys[(hash_old[@@my_key] + 2) % hash_old.size])
        hash_range_to_delete << new_sorted_hash_keys[(hash_new[@@my_key] + 2) % hash_new.size].to_i
        hash_range_to_delete << old_sorted_hash_keys[(hash_old[@@my_key] + 2) % hash_old.size].to_i
      end
      unless hash_range_to_delete.empty?
        log_message('Removing values from range: ' + hash_range_to_delete.to_s)
        remove_values(hash_range_to_delete)
      end
    end
    log_message('Setting new config: ' + new_config.to_s)
    @@dynamo_nodes = new_config
  end

  def remove_values range
    @@key_value_storage.each do |key, _value|
      if range.first < range.second
        if is_higher_and_lower_equal_than?(key, range.first, range.second)
          @@key_value_storage.delete(key)
        end
      else
        if ((is_higher_and_lower_equal_than?(key, range.first, ENV['DYNAMO_MAX_KEY'])) ||
            (is_higher_and_lower_equal_than?(key, 0, range.second)))
          @@key_value_storage.delete(key)
        end
      end
    end
  end

  # store data for self and replicas of the next 2 nodes
  def replicate_data_before_registration
    sorted_hash_keys = @@dynamo_nodes.sort_by { |_k,v| v.first.second.to_i}.map {|_k,v| v.first.second}
    sorted_hash_keys << @@my_key
    sorted_hash_keys = sorted_hash_keys.sort

    hash = Hash[sorted_hash_keys.map.with_index.to_a]

    nodes_to_be_replicated = []
    nodes_to_be_replicated << sorted_hash_keys[(hash[@@my_key] + 1 ) % sorted_hash_keys.size]
    nodes_to_be_replicated << sorted_hash_keys[(hash[@@my_key] + 2 ) % sorted_hash_keys.size]

    @@dynamo_nodes.each do |ip, data|
      if data.first.second.in?(nodes_to_be_replicated)
        data = JSON.parse(HTTPService.get_request('http://' + ip.to_s + '/node/get_data').body)['response']
        data.each do |key, value|
          store_value(key, value)
        end
      end
    end
  end

  def select_my_key_data
    sorted_hash_keys = @@dynamo_nodes.sort_by { |_k,v| v.first.second.to_i}.map {|_k,v| v.first.second}
    hash = Hash[sorted_hash_keys.map.with_index.to_a]

    lower_bound = sorted_hash_keys[(hash[@@my_key] -1 ) % sorted_hash_keys.size].to_i
    higher_bound = sorted_hash_keys[hash[@@my_key]].to_i

    data = {}
    @@key_value_storage.each do | key, value|
      #puts key+"=>"+value
      if lower_bound < higher_bound
        #puts 'FIRST CASE: lower_bound: ' + lower_bound.to_s + ' higher_bound: ' + higher_bound.to_s
        data[key] = value if is_higher_and_lower_equal_than?(key, lower_bound, higher_bound)
      else
        #puts 'SECOND CASE:lower_bound: ' + lower_bound.to_s + ' higher_bound: ' + higher_bound.to_s
        data[key] = value if ((is_higher_and_lower_equal_than?(key, lower_bound, ENV['DYNAMO_MAX_KEY'])) ||
            (is_higher_and_lower_equal_than?(key, 0, higher_bound)))
      end
    end
    data
  end

  def select_data_for_range lower_bound, higher_bound
    unless lower_bound && higher_bound
      return nil
    end
    data = {}
    @@key_value_storage.each do | key, value|
      puts key+"=>"+value
      if lower_bound < higher_bound
        puts 'FIRST CASE: lower_bound: ' + lower_bound.to_s + ' higher_bound: ' + higher_bound.to_s
        data[key] = value if is_higher_and_lower_equal_than?(key, lower_bound, higher_bound)
      else
        puts 'SECOND CASE:lower_bound: ' + lower_bound.to_s + ' higher_bound: ' + higher_bound.to_s
        data[key] = value if ((is_higher_and_lower_equal_than?(key, lower_bound, ENV['DYNAMO_MAX_KEY'])) ||
            (is_higher_and_lower_equal_than?(key, 0, higher_bound)))
      end
    end
    data
  end

  def update_configuration_before_registration
    url = 'http://'+ENV['CONSUL_IP']+':8500/v1/kv/docker_nodes?raw'
    #log_message('Updating configuration from: ' + url)
    response = HTTPService.get_request(url)
    log_message('Updating configuration to: ' + response.body)
    @@dynamo_nodes = JSON.parse(response.body)
  end

  def store_value key, value
    @@key_value_storage[key] ||= value if key
  end

  def coordinate_request type
    nodes = get_responsible_nodes(params[:key])
    log_message('Coordinating request for ' + nodes.size.to_s + ' nodes and type: ' + (type == :get).to_s )
    coordinated_response = []
    nodes.each_with_index do |(key, value),index|
      if @@my_key != value.first.second
        if type == :get
          log_message('Redirecting coordinated request to:' + 'http://' + key + '/node/read_key?&key=' + params[:key] + '&correlation_id=' + params[:correlation_id] + '&coordinated=true')
          response = HTTPService.get_request('http://' + key + '/node/read_key?&key=' + params[:key] + '&correlation_id=' + params[:correlation_id] + '&coordinated=true')
          log_message('Coordinated response body:' + response.body.to_s)
          coordinated_response << (JSON.parse(response.body) unless response.nil? || nil)
        elsif type == :post
          log_message('Redirecting coordinated request to:' + 'http://' + key + '/node/write_key with data: ' + { :key => params[:key], :value => params[:value], :correlation_id => params[:correlation_id], :coordinated => true}.to_s)
          response = HTTPService.post_request('http://' + key + '/node/write_key', { :key => params[:key], :value => params[:value], :correlation_id => params[:correlation_id], :coordinated => true})
          log_message('Coordinated response body:' + response.body.to_s)
          coordinated_response << (JSON.parse(response.body) unless response.nil? || nil)
        end
      else
        if type == :get
          log_message('Reading key:' + params[:key])
          coordinated_response << { 'response' => @@key_value_storage[params[:key]]}
        elsif type == :post
          log_message('Writing key:' + params[:key] + ' with value:' + params[:value])
          store_value(params[:key], params[:value])
          coordinated_response << { 'response' => (@@key_value_storage[params[:key]] || 'Storing value failed') }
        end
      end
    end
    coordinated_response
  end

  def designate_coordinator type
    nodes = get_responsible_nodes(params[:key])
    rand_index = SecureRandom.random_number(3)
    log_message('Designating coordinator for nodes: ' + nodes.size.to_s + ' and type: ' + (type == :get).to_s )
    nodes.each_with_index do |(key, value),index|
      if index == rand_index
        if type == :get
          log_message('Redirecting request to:' + 'http://' + key + '/node/read_key?&key=' + params[:key] + '&correlation_id=' + params[:correlation_id])
          response = HTTPService.get_request('http://' + key + '/node/read_key?&key=' + params[:key] + '&correlation_id=' + params[:correlation_id])
          log_message('Response body:' + response.body.to_s)
          return response.body
        elsif type == :post
          log_message('Redirecting request to:' + 'http://' + key + '/node/write_key with data: ' + { :key => params[:key], :value => params[:value], :correlation_id => params[:correlation_id]}.to_s)
          response = HTTPService.post_request('http://' + key + '/node/write_key', { :key => params[:key], :value => params[:value], :correlation_id => params[:correlation_id]})
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

  # return all nodes responsible for replications of given key
  def get_responsible_nodes key
    responsible_hash_keys = []
    if @@dynamo_nodes.size <= ENV['REPLICATION'].to_i
      return @@dynamo_nodes
    end
    responsible_node_key = 0
    previous = 0

    sorted_hash_keys = @@dynamo_nodes.sort_by { |_k,v| v.first.second.to_i}.map {|_k,v| v.first.second}

    sorted_hash_keys.each do |hash_key|
      #log_message('Comparing key '+key.to_i.to_s+' to hash_key '+hash_key.to_i.to_s)
      if key.to_i <= hash_key.to_i && key.to_i > previous.to_i #key.to_i.between?(previous.to_i,hash_key.to_i)
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
        3.times.each_with_index { |_e, iterator| responsible_hash_keys << sorted_hash_keys[(index - iterator) % sorted_hash_keys.size]}
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
    puts 'REQUEST ' + params[:correlation_id].to_s + ' :: CONTAINER ' + ENV['HOSTNAME'] + ' :: ' + message
  end

  def parse_quorum_json json, type
    if type == :read
      response = json[:read_quorum]
    elsif type == :write
      response = json[:write_quorum]
    end
    response
  end

  def is_higher_and_lower_equal_than? value, lower_bound, higher_bound
    puts 'is: ' + value.to_s + ' higher and lower-equal than?' + ((value.to_i > lower_bound.to_i) && (value.to_i  <= higher_bound.to_i)).to_s
    puts 'lower_bound: ' + lower_bound.to_s + ' higher_bound: ' + higher_bound.to_s
    (value.to_i > lower_bound.to_i) && (value.to_i  <= higher_bound.to_i)
  end

end
