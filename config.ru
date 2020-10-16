require './time_server_rack'

use Rack::ShowExceptions
run Rack::TestApp.new
