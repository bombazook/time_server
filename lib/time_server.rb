# frozen_string_literal: true

Dir[File.join(__dir__, 'time_server', '*.rb')].sort.each { |file| require file }

module TimeServer
  TOKEN = /[!#$%&'*+-.^_`|~0-9a-zA-Z]+/
  MAX_REQUEST_LINE_SIZE = 2**14
  CRLF = "\r\n"
  REQUEST_LINE = %r{\A(#{TOKEN}) ([^\s]+) (HTTP/\d.\d)\z}
end
