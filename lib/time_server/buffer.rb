# frozen_string_literal: true

module TimeServer
  class Buffer < String
    def initialize
      super
      force_encoding(Encoding::BINARY)
    end

    def <<(string)
      if string.encoding == Encoding::BINARY
        super(string)
      else
        super(string.b)
      end

      self
    end
  end
end
