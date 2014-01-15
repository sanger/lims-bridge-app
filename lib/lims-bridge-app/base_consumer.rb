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
      raise NotImplementedError
    end

    def route_message
      raise NotImplementedError
    end
  end
end
