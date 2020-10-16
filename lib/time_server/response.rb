module TimeServer
  class Response
    attr_accessor :status, :body
    def initialize status=200, body=nil
      @status = status
      @body = body
    end
  end
end
