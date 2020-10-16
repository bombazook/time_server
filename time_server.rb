require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'tty'
  gem 'nio4r'
  gem 'timers'
  gem 'tzinfo'
  gem 'byebug'
end
require 'byebug'
require 'nio'
require 'socket'
require 'timers'
require 'tty/cursor'
require 'tzinfo'

host = '127.0.0.1'
port = 1234

selector_backend = ARGV[0] && ARGV[0]&.to_sym || :select
selector = NIO::Selector.new selector_backend
server = TCPServer.new(host, port)
selector.register(server, :r)
timers = Timers::Group.new

TOKEN = /[!#$%&'*+-\.^_`|~0-9a-zA-Z]+/.freeze
REQUEST_LINE = /\AGET ([^\s]+) HTTP\/\d.\d\z/.freeze
CRLF = "\r\n"

class Buffer < String
  BINARY = Encoding::BINARY

  def initialize
    super

    force_encoding(BINARY)
  end

  def << string
    if string.encoding == BINARY
      super(string)
    else
      super(string.b)
    end

    return self
  end

  alias concat <<
end

class RequestLine
  attr_accessor :main_path, :cities
  MAX_REQUEST_LINE_SIZE = 16_384

  def initialize
    @buffer = Buffer.new
  end
  def write data
    if data.include? CRLF
      @buffer << data.partition(CRLF)[0]
      @ready = true
    elsif @buffer.size + data.size > MAX_REQUEST_LINE_SIZE
      @valid = false
    else
      @buffer << data
    end
  end

  def ready?
    @ready == true
  end

  def parse!
    if match = @buffer.match(REQUEST_LINE)
      _, path = *match
      @main_path, _, cities_line = path.partition('?')
      @cities = cities_line&.split(',')
      @valid = true if @main_path == '/time'
    else
      @valid = false
    end
  end

  def valid?
    @valid || !ready?
  end
end

class Response
  attr_accessor :status, :body
  def initialize status=200, body=nil
    @status = status
    @body = body
  end
end

tzmap = {}
TZInfo::Timezone.all.each do |tz|
  key = tz.name.sub(/.*\/(.+)$/,'\1')
  if tzmap[key]
    old_val = tzmap.delete(key)
    tzmap[old_val.name.gsub('/', '-')] = old_val
    tzmap[tz.name.gsub('/', '-')] = tz
  else
    tzmap[key] = tz
  end
end

@r_sockets = Hash.new
@w_sockets = Hash.new
previous_size = 0

STDOUT.write "Listening host #{host} at port #{port}\n with #{selector.backend}"

read_complete = proc do |data, socket|
  request_line = @r_sockets[socket]
  request_line.write data
  if request_line.ready?
    request_line.parse!
    resp_body = tzmap.slice('UTC', *request_line.cities).map do |k,v|
      "#{k}: #{v.now.strftime('%F %T')}"
    end.join("\n")
    @w_sockets[socket] = Writer.new(Response.new(200, resp_body))
  end
end

class Writer
  attr_accessor :offset, :size
  def initialize response
    @response = response
    @offset = 0
    @size = response_data.size
  end

  def response_data
    @response_data ||= begin
      b = Buffer.new
      b << "HTTP/1.1 #{@response.status} OK"
      b << CRLF
      b << CRLF
      b << @response.body
      b
    end
  end

  def data
    response_data.byteslice(@offset..-1)
  end
end

def terminate_socket selector, socket
  @r_sockets.delete(socket)
  @w_sockets.delete(socket)
  selector.deregister(socket)
  socket.close
end

while true
  selector.select do |monitor|
    case io = monitor.io
    when TCPServer
      if monitor.readable?
        if (sock = io.accept_nonblock(exception: false))
          selector.register(sock, :rw)
        end
      end
    when TCPSocket
      begin
        if monitor.readable?
          begin
            @r_sockets[io] = RequestLine.new
            data = io.read_nonblock(16_384)
            read_complete.call(data, io)
          rescue IO::WaitReadable
            monitor = selector.register(io, :r)
            monitor.value = proc do
              STDOUT.write "ELO"
              data = io.read_nonblock(16_384)
              read_complete.call(data, io)
            end
          end
        end
        if monitor.writable? && writer = @w_sockets[io]
          begin
            writer.offset = writer.offset + io.write_nonblock(writer.data)
            terminate_socket(selector, io) if writer.data&.empty?
          rescue IO::WaitWritable
            monitor = selector.register(io, :w)
            monitor.value = proc do
              writer.offset = writer.offset + io.write_nonblock(writer.data)
              terminate_socket(selector, io) if writer.data&.empty?
            end
          end
        end
      rescue EOFError, Errno::ECONNRESET
        STDOUT.write "Listening host #{host} at port #{port}\n with #{selector.backend}"
        terminate_socket(selector, io)
      end
    end
  end
end
