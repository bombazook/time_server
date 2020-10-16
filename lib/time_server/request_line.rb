module TimeServer
  class RequestLine
    attr_accessor :main_path, :cities
    MAX_REQUEST_LINE_SIZE = 2**14

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
end
