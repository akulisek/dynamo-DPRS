class VectorClock

  def self.parse
    hash = {}


    hash
  end

  def self.update_data data, container_id, value
    name, new_data = increment_by_container_id data, container_id
    new_data[:value] = value.to_s
    return name, new_data
  end

  def self.create value, container_ids = []
    unless container_ids.empty? || container_ids.size != ENV['REPLICATION'].to_i
      response = {}
      container_ids.each do |id|
        response[id.to_s] = 0.to_s
      end
      response[:value] = value.to_s
      name = generate_name(response)
    else
      response = 'ERROR: Not enough container_ids provided (' + ENV['REPLICATION'] + ' needed)'
      name = 'ERROR'
    end
    return name, response
  end

  def self.get_name data
    data.keys.first
  end

  private

  def self.increment_by_container_id data, container_id
    data[container_id] = (data[container_id].to_i + 1).to_s
    return generate_name(data), data
  end

  def self.generate_name data
    response = ''
    data.sort_by{ |k, _v| k.to_s }.each do |key, value|
      next if key.to_s == :value.to_s
      response << key.to_s + '=' + value.to_s + ';'
    end
    response
  end

end
