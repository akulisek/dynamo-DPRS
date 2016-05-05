class NodeController < ApplicationController

  def index
    puts "NodeController#index #{Rails.env}"
    logger.warn "Hello from NodeController!"
  end

end
