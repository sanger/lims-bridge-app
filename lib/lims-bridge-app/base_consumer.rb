require 'lims-busclient'
require 'lims-bridge-app/message_bus'
require 'lims-bridge-app/decoders/all'
require 'lims-bridge-app/message_handlers/all'

module Lims::BridgeApp
  class BaseConsumer
    include Lims::BusClient::Consumer

    InvalidParameters = Class.new(StandardError) 
    NoRouteFound = Class.new(StandardError)

    attribute :queue_name, String, :required => true, :writer => :private, :reader => :private
    attribute :log, Object, :required => false, :writer => :private
    attribute :bus, Lims::BridgeApp::MessageBus, :required => true, :writer => :private
    attribute :settings, Hash, :required => true, :writer => :private

    # @param [Class] subclass
    # Setup the validation of bridge settings
    def self.inherited(subclass)
      subclass.class_eval do
        include Virtus
        include Aequitas
        validates_with_method :validate_settings

        def validate_settings
          self.class::SETTINGS.each do |attribute, type|
            raise InvalidParameters, "The setting #{attribute} is required" unless settings[attribute.to_s]
            raise InvalidParameters, "The setting #{attribute} must be a #{type}" unless settings[attribute.to_s].is_a?(type)
          end
          true
        end
      end
    end

    # @param [Hash] AMQP settings
    # @param [Hash] bridge settings
    def initialize(amqp_settings, bridge_settings)
      sequencescape_bus_settings = amqp_settings.delete("sequencescape").first.tap do |settings|
        settings["backend_application_id"] = "lims-bridge-app"
      end
      @bus = MessageBus.new(sequencescape_bus_settings)
      @settings = bridge_settings
      consumer_setup(amqp_settings)
    end

    def run
      process_messages
    end

    # @param [Logger] logger
    def set_logger(logger)
      @log = logger
    end

    private

    def process_messages
      self.add_queue(queue_name) do |metadata, payload|
        log.info("Message received with the routing key: #{metadata.routing_key}")
        log.debug("Processing message with routing key: '#{metadata.routing_key}' and payload: #{payload}")
        decoded_resource = Decoders::BaseDecoder.decode(payload)
        route_message(metadata, decoded_resource)
      end
    end

    # @param [AMQP::Header] metadata
    # @param [Hash] resource
    def route_message(metadata, resource)
      begin
        route = route_for(metadata.routing_key)
        handler_class = MessageHandlers.handler_for(route) 
        handler_class.new(bus, log, metadata, resource, settings).tap do |handler_instance|
          handler_instance.call
        end
      rescue NoRouteFound => e
        log.error("No route found for the message #{metadata.routing_key}: #{e}")
        metadata.reject
      rescue MessageHandlers::UndefinedHandler => e
        log.error("The handler for the route #{route} cannot be found: #{e}")
        metadata.reject
      end
    end

    def route_for(routing_key)
      raise NotImplementedError
    end
  end
end
