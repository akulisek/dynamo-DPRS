class NodeController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:read_key_value, :write_key_value]

  @@key_value_storage = {}

  def index
    puts "NodeController#index #{Rails.env}"
    logger.warn "Hello from NodeController!"
  end

  def read_key_value
    if params[:key]
      value = @@key_value_storage[params[:key]]
    end
    logger.warn "Reading key: #{params[:key]} with value: #{params[:value]}"
    respond_to do |format|
      format.json { render :json => { params[:key] => value} }
    end
  end

  def write_key_value
    if params[:key] && params[:value]
      @@key_value_storage[params[:key]] = params[:value]
    end
    logger.warn "Writing key: #{params[:key]} with value: #{params[:value]}"
    respond_to do |format|
      format.json { render :json => { params[:key] => @@key_value_storage[params[:key]] } }
    end
  end

  def update_configuration
    url = 'http://'+ENV['CONSUL_IP']+':8500/v1/catalog/services'
    logger.warn url
    response = IPService.get_request(url)
    logger.warn response
    logger.warn response.body
    respond_to do |format|
      format.json { render :json => response.body }
    end
  end

  private

end
