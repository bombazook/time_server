# frozen_string_literal: true

module TimeServer
  class Application
    def call(request)
      if request.path =~ %r{/time($|\?)}
        ids = request.query_string&.split(',')
        resp_body = TimeServer::TZMap.times_by_ids(ids).join("\r\n")
        [200, { 'Content-type' => 'text/plain', 'Content-length' => resp_body.size.to_s }, [resp_body]]
      else
        resp_body = 'Wrong request'
        [400, { 'Content-type' => 'text/plain', 'Content-length' => resp_body.size.to_s }, [resp_body]]
      end
    end
  end
end
