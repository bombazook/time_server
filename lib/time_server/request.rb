# frozen_string_literal: true

module TimeServer
  class Request
    attr_reader :path, :method, :version

    def initialize(connection)
      @connection = connection
      first_line = connection.read_until CRLF
      if !first_line || !match = first_line.match(REQUEST_LINE)
        raise InvalidRequest
      else
        _, @method, @path, @version = *match
      end
    end

    def query_string
      @path&.sub(/.*\?/, '')
    end

  end
end
