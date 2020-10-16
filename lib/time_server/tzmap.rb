# frozen_string_literal: true

require 'tzinfo'
require 'forwardable'

module TimeServer
  class TZMap
    class << self
      extend Forwardable
      def_delegators :@tzmap, :slice, :keys

      def reload!
        @tzmap = {}
        TZInfo::Timezone.all.each do |tz|
          key = tz.name.sub(%r{.*/(.+)$}, '\1')
          if @tzmap[key]
            old_val = @tzmap.delete(key)
            @tzmap[old_val.name.gsub('/', '-')] = old_val
            @tzmap[tz.name.gsub('/', '-')] = tz
          else
            @tzmap[key] = tz
          end
        end
      end

      def times_by_ids(ids = [], format = '%F %T')
        @tzmap.slice('UTC', *ids).map do |k, v|
          "#{k}: #{v.now.strftime(format)}"
        end
      end
    end

    reload!
  end
end
