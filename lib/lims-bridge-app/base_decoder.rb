require 'json'

module Lims::BridgeApp
  module Decoders

    UndefinedDecoder = Class.new(StandardError)

    class BaseDecoder
      attr_reader :resource_hash, :resource_uuid

      # @param [String] payload
      # @param [Hash] options
      def initialize(payload, options)
        @payload = payload
        @options = options
      end

      # @return [Hash]
      def call
        decoded_resource = _call
        to_merge = {:date => @options[:date]}
        to_merge[:uuid] = resource_uuid if resource_uuid
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

      S2_REST_ACTIONS = [:create, :update, :delete]

      # @param [Class] klass
      # Automatically create default decoders for each children class
      # inheriting BaseDecoder. It creates decoders for the create/update/delete
      # actions of the resource called as a s2 action.
      # Example: For GelDecoder, it will create a decode_create_gel, which is 
      # called when we receive a message "create_gel", result of a post request
      # to "actions/create_gel".
      # TODO: limit the creation of these classes to S2 resources (currently, 
      # it works for every decoder, even plate_transfer)
      def self.inherited(klass)
        # Avoid infinite call to inherited method as we define here new child classes
        return unless klass.superclass == BaseDecoder
        klass.to_s =~ /::(\w+)Decoder$/
        resource_name = $1
        resource_name_snakecase = resource_name.gsub(/(.)([A-Z])/, '\1_\2').downcase
        S2_REST_ACTIONS.each do |action|
          Decoders.class_eval %Q{ 
            class #{action.to_s.capitalize}#{resource_name}Decoder < #{klass} 
              def decode_#{action.to_s}_#{resource_name_snakecase}
                @payload = resource_hash["result"]
                send("decode_#{resource_name_snakecase}")
              end
            end
          }
        end
      end

      # @param [String] model
      # @return [Class]
      # @raise [UndefinedDecoder]
      def self.decoder_for(model)
        begin
          decoder = "#{model.to_s.capitalize.gsub(/_./) {|p| p[1].upcase}}Decoder"
          Decoders::const_get(decoder)
        rescue NameError => e
          raise UndefinedDecoder, "#{decoder} is undefined"
        end
      end

      def resource_uuid
        resource_hash["uuid"]
      end

      def resource_hash
        @payload[resource_key]
      end

      def resource_key
        @payload.keys.first.to_s
      end

      # @return [Object]
      # @raise [UndefinedDecoder]
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
