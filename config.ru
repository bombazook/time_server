# frozen_string_literal: true

require './time_server_rack'

use Rack::ShowExceptions
run Rack::TestApp.new
