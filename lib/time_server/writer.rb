module TimeServer
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
        b << "Connection: close"
        b << CRLF
        b << @response.body
        b
      end
    end

    def data
      response_data.byteslice(@offset..-1)
    end
  end
end
