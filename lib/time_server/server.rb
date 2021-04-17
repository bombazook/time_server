# frozen_string_literal: true

module TimeServer
  class Server
    attr_accessor :application

    def options
      @options ||= {}
    end

    def initialize(server, selector)
      @monitor = selector.register(server, :r)
      @selector = selector
      @fiber = Fiber.new do
        while true
          accept(@monitor.io)
          Fiber.yield
        end
      end
      @monitor.value = @fiber
      @fiber.resume if @monitor.readable?
    end

    def accept(io)
      socket = io.accept_nonblock(exception: false)
      return if socket == :wait_readable
      
      connection = Connection.new(socket, @selector, **options.slice(:block_size))
      Fiber.new do
        request = Request.new(connection)
        response = Response[*application.call(request)]
        respond_and_close connection, response
      rescue InvalidRequest
        resp_body = 'Unknown error'
        response = Response[500, { 'Content-type' => 'text/plain', 'Content-length' => resp_body.bytesize.to_s },
                            [resp_body]]
        respond_and_close connection, response
      end.resume
    end

    def respond_and_close(connection, response)
      connection.close_read
      connection.write(response.to_s)
    ensure
      connection.close
    end
  end
end
