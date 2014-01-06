module Lims::BridgeApp
  module Decoders
    class BaseDecoder

      UndefinedDecoder = Class.new(StandardError)

      attr_reader :resource_hash, :resource_uuid

      # @param [String] payload
      # @param [Hash] options
      def initialize(payload, options)
        @payload = payload
        @resource_hash = payload[resource_key]
        @resource_uuid = @resource_hash["uuid"] if @resource_hash.has_key?("uuid")
        @options = options
      end

      # @return [Hash]
      def call
        decoded_resource = _call

        to_merge = {:date => options[:date]}
        to_merge[:uuid] = @resource_uuid if @resource_uuid

        if decoded_resource.is_a?(Hash)
          decoded_resource.merge!(to_merge)
        else
          {resource_key.to_sym => decoded_resource}.merge!(to_merge)
        end
      end

      # @param [String] message
      # @return [Hash]
      def self.decode(message)
        body = JSON.parse(message)
        action = body.delete("action")
        user = body.delete("user")
        date = Time.parse(body.delete("date"))
        options = {:action => action, :date => date, :user => user}

        model = body.keys.first
        decoder_for(model).new(body, options).call
      end

      private

      # @param [String] model
      # @return [Class]
      def self.decoder_for(model)
        begin
          decoder = "#{model.to_s.capitalize.gsub(/_./) {|p| p[1].upcase}}Decoder"
          Decoders::const_get(decoder)
        rescue NameError => e
          raise UndefinedDecoder, "#{decoder} is undefined"
        end
      end

      # @return [String]
      def resource_key
        @payload.keys.first.to_s
      end

      def _call
        begin
          self.send("decode_#{resource_key}")
        rescue
          raise UndefinedDecoder, "The decoder for #{resource_key} is undefined"
        end
      end
    end
  end
end
