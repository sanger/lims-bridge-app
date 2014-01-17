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
