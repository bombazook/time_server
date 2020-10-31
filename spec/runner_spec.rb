require 'spec_helper'

RSpec.describe TimeServer::Runner do
  def do_test(string, chunk=2**12, slow=nil)
    socket = TCPSocket.new("127.0.0.1", "1234")
    request = StringIO.new(string)
    chunks_out = 0

    while data = request.read(chunk)
      chunks_out += socket.write(data)
      sleep slow if slow
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

  def wait_untill_available
    do_test("GET /time HTTP/1.1\r\n\r\n").read
  rescue Errno::ECONNREFUSED
    retry
  end

  def multiple_requests request
    50.times.map do |i|
      Thread.new do
        response = do_test(request).read
      end
    end.map(&:join)
  end

  before :all do
    @application = TimeServer::Application.new
    @server = described_class.new(@application, bind: "http://127.0.0.1:1234")
    @server.run true
    wait_untill_available
  end

  after :all do
    @server.stop
  end

  context "/time" do
    context "correct requests" do
      it "responds on two sequential requests" do
        request1 = "GET /time HTTP/1.1\r\n\r\n"
        response1 = do_test(request1).read
        expect(response1).to match(/^HTTP\/\d\.\d\ 200\ OK\r\n.*\r\nUTC:\ /mx)

        request2 = "GET /time?Moscow HTTP/1.1\r\n\r\n"
        response2 = do_test(request2).read
        expect(response2).to match(/^HTTP\/\d\.\d\ 200\ OK\r\n.*\r\nUTC:\ .*\r\nMoscow:\ /mx)
      end

      it "responds on multiple simultaneous request at the same time" do
        request = "GET /time HTTP/1.1\r\n\r\n"
        map = 10.times.map{ do_test(request, 2).read(4) }
        expect(map).to match_array(10.times.map{"HTTP"})
      end

      it "responds with UTC: <time> if query is empty" do
        request = "GET /time HTTP/1.1\r\n\r\n"
        response = do_test(request).read
        expect(response).to match(/^HTTP\/\d\.\d\ 200\ OK\r\n.+\r\n\r\nUTC:\ /mx)
      end

      it "responds with <city>: <time> on each line if query includes <city>,..." do
        request = "GET /time?Moscow HTTP/1.1\r\n\r\n"
        response = do_test(request).read
        expect(response).to match(/^HTTP\/\d\.\d\ 200\ OK\r\n.+\r\n\r\nUTC:\ .*\r\nMoscow:\ /mx)
      end

      context "request longer than read chunk size" do
        it "responds well" do
          keys = TimeServer::TZMap.keys
          key_string = keys.join(',')
          request = "GET /time?#{key_string} HTTP/1.1\r\n\r\n"
          response = read_response(do_test(request))
          expect(response).to include(*keys)
        end
      end

      context "slow request" do
        it "doesnt block" do
          request = "GET /time?Moscow HTTP/1.1\r\n\r\n"
          Thread.new do
            do_test(request, 10, 1000).read
          end
          response = do_test(request).read
          expect(response).to match(/^HTTP\/\d\.\d\ 200\ OK\r\n.+\r\n\r\nUTC:\ .*\r\nMoscow:\ /mx)
        end
      end
    end

    context "request line is longer than limit" do
      xit "returns 501 code (rfc7230 3.1.1)" do
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
