require 'set'
# create a simple object to mimic the puppet type Netbase::Service
module PuppetX
  module Netbase
    class Service
      attr_reader :name, :port, :protocols, :aliases
      def initialize(name, data, strict)
        @name = name
        @port = data['port']
        @protocols = data['protocols']
        @portend = data.fetch('portend', nil)
        @aliases = data.fetch('aliases', []).to_set
        @description = data.fetch('description', nil)
        # This allow us to either compare via proto and port or just port
        # it's not great having this in the object class but it allows us to
        # abuse set comparisons
        @strict = strict
      end
      # override ==, eq? and hash to allow use to do set comparisons
      # == is not strictly required for set comparisons but make sense
      # to also include this
      def ==(other)
        hash == other.hash
      end
      def eql?(other)
        hash == other.hash
      end
      def hash
        if @strict
          "#{@port}_#{@protocols.join}".hash
        else
          @port.hash
        end
      end
      def puppet_type
        result = {
          'protocols' => @protocols,
          'port' => @port,
        }
        result['portend'] = @portend unless @portend.nil?
        result['description'] = @description unless @description.nil?
        result['aliases'] = @aliases.to_a unless @aliases.empty?
        result
      end
    end
  end
end
