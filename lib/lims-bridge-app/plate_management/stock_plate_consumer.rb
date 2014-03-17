require 'lims-busclient'
require 'lims-bridge-app/plate_management/json_decoder'
require 'lims-bridge-app/plate_management/sequencescape_updater'
require 'lims-bridge-app/plate_management/message_handlers/all'
require 'lims-bridge-app/base_consumer'
require 'lims-bridge-app/message_bus'

module Lims::BridgeApp
  module PlateManagement
    # When a stock plate is created on S2, it must be created in
    # Sequencescape as well. To identify a stock plate creation in S2,
    # two kinds of message need to be recorded on the message bus:
    # plate creation messages and order creation/update messages.
    # Plate creation messages contain the structure of the plate, whereas 
    # order messages identify the type of the plate in its items. 
    # Every time a plate creation message is received, a new plate is 
    # created in Sequencescape side with a plate purpose set to Unassigned.
    # As soon as we receive an order message which references a plate which 
    # has been created in SS, its plate purpose is updated to Stock Plate.
    # If a stock plate appears in an order message but cannot be found in 
    # Sequencescape database, it means the order message has been received 
    # before the plate creation message. The order message is then requeued 
    # waiting for the plate message to arrive.
    # Note: S2 tuberacks are treated like plates in Sequencescape.
    class StockPlateConsumer < BaseConsumer
      include JsonDecoder

      SETTINGS = {:well_type => String, :plate_type => String, :asset_type => String, :sample_type => String,
                  :roles_purpose_ids => Hash, :unassigned_plate_purpose_id => Integer, 
                  :item_role_patterns => Array, :item_done_status => String, :sanger_barcode_type => String, 
                  :plate_location => String, :create_asset_request_sti_type => String, :create_asset_request_type_id => Integer, 
                  :create_asset_request_state => String, :transfer_request_sti_type => String, :transfer_request_type_id => Integer,
                  :transfer_request_state => String, :barcode_prefixes => Hash, :out_of_bounds_concentration_key => String,
                  :stock_plate_concentration_multiplier => Float}

      # @param [Hash] amqp_settings
      # @param [Hash] mysql_settings
      # @param [Hash] bridge_settings
      def initialize(amqp_settings, mysql_settings, bridge_settings)
        @queue_name = amqp_settings.delete("plate_management_queue_name")
        super(amqp_settings, mysql_settings, bridge_settings)
      end

      private

      # Setup the queue.
      # 3 different behaviours depending on the routing key
      # of the message (plate/plate_transfer/order). 
      def set_queue
        self.add_queue(queue_name) do |metadata, payload|
          log.info("Message received with the routing key: #{metadata.routing_key}")
          log.debug("Processing message with routing key: '#{metadata.routing_key}' and payload: #{payload}")
          s2_resource = s2_resource(payload)
          route_message(metadata, s2_resource)
        end
      end

      # @param [AMQP::Header] metadata
      # @param [Hash] s2_resource
      # Route the message to the correct handler method
      def route_message(metadata, s2_resource)
        handler_for = lambda do |type|
          klass = "#{type.to_s.capitalize.gsub(/_./) {|p| p[1].upcase}}Handler"         
          handler_class = PlateManagement::MessageHandler.const_get(klass)  
          handler_class.new(db, bus, log, metadata, s2_resource, settings)
        end

        case metadata.routing_key
        # Plate and tuberack are stored in the same place in sequencescape
        when /(plate|tuberack|gel)\.create/ then handler_for[:plate].call
          # Gel image
        when /gelimage/ then handler_for[:gel_image].call
          # On reception of an order creation/update message
        when /order\.(create|updateorder)/ then handler_for[:order].call
          # On reception of a plate update message
        when /updatetuberack|updateplate|updategel/ then handler_for[:update_aliquots].call
          # On reception of a plate transfer message
        when /platetransfer|transferplatestoplates|tuberacktransfer/ then handler_for[:transfer].call
          # Tube rack move messages have a custom handler as it needs to delete aliquots in the source racks.
        when /tuberackmove/ then handler_for[:tube_rack_move].call
        when /deletetuberack/ then handler_for[:plate_delete].call
        when /label/ then handler_for[:labellable].call
        when /swapsamples/ then handler_for[:swap_samples].call
        end
      end
    end
  end
end
