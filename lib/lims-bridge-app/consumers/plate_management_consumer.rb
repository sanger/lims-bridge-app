require 'lims-bridge-app/base_consumer'

module Lims::BridgeApp
  class PlateManagementConsumer < BaseConsumer

    SETTINGS = {:well_type => String, :plate_type => String, :asset_type => String, :sample_type => String,
                :roles_purpose_ids => Hash, :unassigned_plate_purpose_id => Integer, 
                :item_role_patterns => Array, :item_done_status => String, :sanger_barcode_type => String, 
                :plate_location => String, :create_asset_request_sti_type => String, :create_asset_request_type_id => Integer, 
                :create_asset_request_state => String, :transfer_request_sti_type => String, :transfer_request_type_id => Integer,
                :transfer_request_state => String, :barcode_prefixes => Hash, :out_of_bounds_concentration_key => String,
                :stock_plate_concentration_multiplier => Float}

    # @param [Hash] amqp_settings
    # @param [Hash] bridge_settings
    def initialize(amqp_settings, bridge_settings)
      @queue_name = amqp_settings.delete("plate_management_queue_name")
      super(amqp_settings, bridge_settings)
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

    # @param [String] routing_key
    # @return [Symbol]
    # @raise [NoRouteFound]
    def route_for(routing_key)
      case routing_key
      when /(plate|tuberack|gel)\.create/                           then :asset_creation
      when /gelimage/                                               then :gel_image
      when /order\.(create|update)/                                 then :order
      when /updatetuberack|updateplate|updategel/                   then :aliquots_update
      when /platetransfer|transferplatestoplates|tuberacktransfer/  then :transfer
      when /tuberackmove/                                           then :tube_rack_move
      when /deletetuberack/                                         then :asset_deletion
      when /label/                                                  then :labellable
      when /swapsamples/                                            then :samples_swap
      else raise NoRouteFound, "No route found for routing key #{routing_key}"
      end   
    end
  end
end
