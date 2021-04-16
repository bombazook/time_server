#!/usr/bin/env ruby

require 'nio'
require 'socket'
require 'addressable/uri'

module TimeServer
  class Runner
    def initialize application=nil, **options
      @options = options
      @application = application
      trap("INT"){ stop }
      trap("EXIT"){ stop }
    end

    def run background=false, &application
      if background == true
        @thread = Thread.new do
          handle_server &application
        end
      else
        handle_server &application
      end
    end

    def stop
      @stopped = true
      @tcp_server.close
    end

    def build_server
      @selector = NIO::Selector.new @options[:selector]
      uri = Addressable::URI.parse(@options[:bind])
      @tcp_server = TCPServer.new(uri.host, uri.port)
      @server = TimeServer::Server.new(@tcp_server, @selector)
      @server.application = @application
      @server.options[:block_size] = @options[:block_size]
    end

    def handle_server &application
      build_server
      @server.application = application if block_given?
      while !@stopped
        @selector.select do |monitor|
          monitor.value.resume
        end
      end
    end
  end
end
