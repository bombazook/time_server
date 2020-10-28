Dir[File.join(__dir__, 'time_server', '*.rb')].sort.each { |file| require file }

module TimeServer
  TOKEN = /[!#$%&'*+-\.^_`|~0-9a-zA-Z]+/.freeze
  MAX_REQUEST_LINE_SIZE = 2**14
  CRLF = "\r\n".freeze
  REQUEST_LINE = /\A(#{TOKEN}) ([^\s]+) (HTTP\/\d.\d)\z/.freeze
end
