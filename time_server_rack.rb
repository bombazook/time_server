# frozen_string_literal: true

require 'rack'
require_relative 'lib/time_server/tzmap'

module Rack
  class TestApp
    def call(env)
      if env[REQUEST_PATH] =~ /\/time($|\?)/
        ids = env[QUERY_STRING]&.split(',')
        resp_body = TimeServer::TZMap.times_by_ids(ids).join("\r\n")
        [200, { CONTENT_TYPE => 'text/plain', CONTENT_LENGTH => resp_body.size.to_s }, [resp_body]]
      else
        [400, {},["Wrong request"]]
      end
    end
  end
end

Rack::Server.start(app: Rack::TestApp.new, Port: 1234) if $PROGRAM_NAME == __FILE__
