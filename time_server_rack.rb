# frozen_string_literal: true

require 'rack'
require_relative 'lib/time_server/tzmap'
require_relative 'lib/time_server/application'

module Rack
  class TestApp
    def initialize
      @app = TimeServer::Application.new
    end

    def call(env)
      request = Rack::Request.new(env)
      @app.call(request)
    end
  end
end

Rack::Server.start(app: Rack::TestApp.new, Port: 1234) if $PROGRAM_NAME == __FILE__
