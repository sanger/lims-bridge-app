require 'lims-bridge-app/base_consumer'

module Lims::BridgeApp
  class SampleManagementConsumer < BaseConsumer
    
    SETTINGS = {:sample_type => String, :study_sample_type => String}

    # @param [Hash] amqp_settings
    # @param [Hash] bridge_settings
    def initialize(amqp_settings, bridge_settings)
      @queue_name = amqp_settings.delete("sample_queue_name")
      super(amqp_settings, bridge_settings)
    end

    private

    # @param [String] routing_key
    # @return [Symbol]
    # @raise [NoRouteFound]
    def route_for(routing_key)
      case routing_key
      when /sample\.create|bulkcreatesample/        then :sample_creation
      when /sample\.updatesample|bulkupdatesample/  then :sample_update
      when /sample\.deletesample|bulkdeletesample/  then :sample_deletion
      else raise NoRouteFound, "No route found for routing key #{routing_key}"
      end
    end
  end
end
