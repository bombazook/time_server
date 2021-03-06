# frozen_string_literal: true

require 'fiber'
require 'forwardable'

module TimeServer
  class Connection
    extend Forwardable

    def_delegators :@io, :closed?, :close_read

    def initialize(io, selector, **options)
      @io = io
      @selector = selector
      @options = options
      @options[:block_size] ||= 2**12
      @monitor = nil
      @read_buffer = Buffer.new
    end

    def read_partial(size = @options[:block_size])
      size ||= @options[:block_size]
      reader_monitor
      while true
        data = @io.read_nonblock(size, exception: false)
        if data == :wait_readable
          Fiber.yield
        elsif data.nil?
          @monitor.remove_interest :r
          @monitor.io.close_read
          return
        else
          @monitor.remove_interest :r
          return data
        end
      end
    end

    def read_until(pattern, offset = 0, chomp: true)
      pattern_size = pattern.bytesize
      split_offset = pattern_size - 1

      until index = @read_buffer.index(pattern, offset)
        offset = @read_buffer.bytesize - split_offset
        offset = 0 if offset.negative?

        partial = read_partial
        return unless partial # EOF

        @read_buffer << partial
      end

      chunk_size = index + (chomp ? 0 : pattern_size)
      chunk = @read_buffer.byteslice(0, chunk_size)
      @read_buffer = @read_buffer.byteslice(index + pattern_size, @read_buffer.bytesize)
      chunk
    end

    def write(buffer)
      writer_monitor
      written = 0
      remaining = buffer.size
      while remaining.positive?
        writing = buffer.byteslice(written, remaining)
        length = @io.write_nonblock(writing, exception: false)
        if length == :wait_writable
          Fiber.yield
        else
          remaining -= length
          written += length
        end
      end
      @monitor.remove_interest :w
      written
    end

    def close
      @selector.deregister(@io)
      @io.close
    end

    private

    def reader_monitor
      unless @monitor
        @monitor = @selector.register(@io, :r)
        @monitor.value = Fiber.current
      end
      @monitor.add_interest :r
    end

    def writer_monitor
      unless @monitor
        @monitor = @selector.register(@io, :w)
        @monitor.value = Fiber.current
      end
      @monitor.add_interest :w
    end
  end
end
