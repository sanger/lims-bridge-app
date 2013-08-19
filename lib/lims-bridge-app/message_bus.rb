require 'lims-core/persistence/message_bus'
require 'json'

module Lims::BridgeApp
  class MessageBus
    include Virtus
    include Aequitas
    attribute :bus, Lims::Core::Persistence::MessageBus, :required => true, :writer => :private
    attribute :routing_key, String, :required => true, :writer => :private

    # @param [Hash] settings
    def initialize(settings)
      @routing_key = settings.delete("routing_key")
      @bus = message_bus_connection(settings) 
    end

    # @param [String] message
    def publish(message)
      bus.publish(message.to_json, :routing_key => routing_key)
    end

    # @param [Hash] settings
    # @return [Lims::Core::Persistence::MessageBus]
    def message_bus_connection(settings)
      Lims::Core::Persistence::MessageBus.new(settings).tap do |bus|
        bus.set_message_persistence(settings["message_persistence"])
        bus.connect
      end
    end
    private :message_bus_connection
  end
end
