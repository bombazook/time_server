require_relative 'time_server/endpoint'
require_relative 'time_server/server'

module TimeServer
  TOKEN = /[!#$%&'*+-\.^_`|~0-9a-zA-Z]+/.freeze
  REQUEST_LINE = /\AGET ([^\s]+) HTTP\/\d.\d\z/.freeze
  CRLF = "\r\n"
end
