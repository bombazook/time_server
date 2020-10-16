#!/usr/bin/env ruby

require 'nio'
require 'socket'
require 'addressable/uri'
require_relative 'buffer'
require_relative 'writer'
require_relative 'response'
require_relative 'tzmap'
require_relative 'request_line'


module TimeServer
  class Server
    READ_BUFFER = 2**12
    WRITE_BUFFER = 2**12

    def read_complete data, socket
      request_line = @r_sockets[socket]
      request_line.write data
      if request_line.ready?
        socket.close_read
        request_line.parse!
        resp_body = TZMap.times_by_ids(request_line.cities).join("\r\n")
        @w_sockets[socket] = Writer.new(Response.new(200, resp_body))
      end
    end

    def initialize bind:, selector: "select", buffers: {}
      @read_buffer = buffers&.send(:[], :read) || READ_BUFFER
      @write_buffer = buffers&.send(:[], :write) || WRITE_BUFFER
      @selector = NIO::Selector.new selector.to_sym
      uri = Addressable::URI.parse(bind)
      @tcp_server = TCPServer.new(uri.host, uri.port)
      @selector.register(@tcp_server, :r)
      @r_sockets = Hash.new
      @w_sockets = Hash.new
      STDOUT.write "Listening #{uri.to_s}\n with #{@selector.backend} and read buffer #{@read_buffer}"
    end

    def terminate_socket socket
      @r_sockets.delete(socket)
      @w_sockets.delete(socket)
      @selector.deregister(socket)
      socket.close
    end

    def run background=false
      if background == true
        @thread = Thread.new do
          handle_server
        end
      else
        handle_server
      end
    end

    def stop
      @stopped = true
    end

    def handle_server
      while !@stopped
        @selector.select do |monitor|
          case io = monitor.io
          when TCPServer
            if monitor.readable?
              if (sock = io.accept_nonblock(exception: false))
                @selector.register(sock, :rw)
              end
            end
          when TCPSocket
            begin
              if monitor.readable?
                begin
                  @r_sockets[io] ||= RequestLine.new
                  data = io.read_nonblock(@read_buffer)
                  read_complete(data, io)
                rescue IO::WaitReadable
                  @selector.register(io, :r)
                end
              end
              if monitor.writable? && writer = @w_sockets[io]
                begin
                  writer.offset = writer.offset + io.write_nonblock(writer.data)
                  terminate_socket(io) if writer.data&.empty?
                rescue IO::WaitWritable
                  @selector.register(io, :w)
                end
              end
            rescue EOFError, Errno::ECONNRESET => e
              terminate_socket(io)
            end
          end
        end
      end
    end
  end
end
