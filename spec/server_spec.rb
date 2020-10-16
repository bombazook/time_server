require 'spec_helper'

RSpec.describe TimeServer::Server do
  def do_test(string, chunk=2**12)
    socket = TCPSocket.new("127.0.0.1", "1234");
    request = StringIO.new(string)
    chunks_out = 0

    while data = request.read(chunk)
      chunks_out += socket.write(data)
      socket.flush
    end
    socket
  end

  def read_response(io, chunk=2**12)
    response = StringIO.new
    while data = io.read(chunk)
      response.write data
    end
    response.string
  end

  before :all do
    @server = described_class.new(bind: "http://127.0.0.1:1234", buffers: {read: 512})
    @server.run true
  end

  after :all do
    @server.stop
  end

  context "/time" do
    context "correct requests" do
      it "responds on two sequential requests" do
        request1 = "GET /time HTTP/1.1\r\n\r\n"
        response1 = do_test(request1).read
        expect(response1).to match(/^HTTP\/\d\.\d\ 200 OK\r\n.*\r\nUTC:\ /)

        request2 = "GET /time?Moscow HTTP/1.1\r\n\r\n"
        response2 = do_test(request2).read
        expect(response2).to match(/^HTTP\/\d\.\d\ 200 OK\r\n.*\r\nUTC:\ .*\r\nMoscow:\ /)
      end

      it "responds with UTC: <time> if query is empty" do
        request = "GET /time HTTP/1.1\r\n\r\n"
        response = do_test(request).read
        expect(response).to match(/^HTTP\/\d\.\d\ 200 OK\r\n.*\r\nUTC:\ /)
      end

      it "responds with <city>: <time> on each line if query includes <city>,..." do
        request = "GET /time?Moscow HTTP/1.1\r\n\r\n"
        response = do_test(request).read
        expect(response).to match(/^HTTP\/\d\.\d\ 200 OK\r\n.*\r\nUTC:\ .*\r\nMoscow:\ /)
      end

      context "request longer than read buffer" do
        it "responds well" do
          keys = TimeServer::TZMap.keys
          key_string = keys.join(',')
          request = "GET /time?#{key_string} HTTP/1.1\r\n\r\n"
          response = read_response(do_test(request))
          expect(response).to include(*keys)
        end
      end

      context "response longer than write buffer" do
      end
    end
  end

  context "/blah" do
    xit "returns redirect to /time" do
      request = "GET /blah HTTP/1.1\r\n\r\n"
      response = do_test(request).read
      expect(response).to match(/^HTTP\/\d\.\d\ 308/)
    end
  end
end
