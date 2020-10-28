module TimeServer
  class Response
    REASON_DESCRIPTIONS = {
      400 => "Bad Request",
      200 => "OK",
      500 => "Internal Server Error"
    }

    attr_accessor :status, :body

    def self.[] status, headers, body
      self.new(body, status, headers)
    end

    def initialize(body = nil, status = 200, headers = {})
      @status = status
      @body = body
      @headers = headers
    end

    def to_s
      b = Buffer.new
      b << "HTTP/1.1 #{@status} #{reason}"
      b << CRLF
      if !@headers&.empty?
        b << @headers.flat_map{|k,v| "#{k}: #{v}"}.join(CRLF)
        b << CRLF
      end
      b << CRLF
      b << @body.join
      b
    end

    def reason
      REASON_DESCRIPTIONS[@status] || REASON_DESCRIPTIONS[500]
    end
  end
end
