require 'lims-busclient'
require 'lims-bridge-app/plate_creator/json_decoder'
require 'lims-bridge-app/plate_creator/sequencescape_updater'
require 'lims-bridge-app/plate_creator/message_handlers/all'
require 'lims-bridge-app/s2_resource'
require 'lims-bridge-app/message_bus'
require 'lims-bridge-app/validator'

module Lims::BridgeApp
  module PlateCreator
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
    class StockPlateConsumer
      include Lims::BusClient::Consumer
      include JsonDecoder
      include S2Resource
      include Virtus
      include Aequitas
      include Validator

      attribute :queue_name, String, :required => true, :writer => :private, :reader => :private
      attribute :log, Object, :required => false, :writer => :private
      attribute :db, Sequel::Mysql2::Database, :required => true, :writer => :private, :reader => :private
      attribute :bus, Lims::BridgeApp::MessageBus, :required => true, :writer => :private
      attribute :settings, Hash, :required => true, :writer => :private
      validates_with_method :settings_validation

      SETTINGS = {:well_type => String, :plate_type => String, :asset_type => String, :sample_type => String,
                  :stock_dna_plate_role => String, :stock_rna_plate_role => String, :stock_dna_plate_purpose_id => Integer, 
                  :stock_rna_plate_purpose_id => Integer, :unassigned_plate_purpose_id => Integer, 
                  :stock_plate_patterns => Array, :item_done_status => String, :sanger_barcode_type => String, 
                  :plate_location => String, :request_sti_type => String, :request_type_id => Integer, 
                  :request_state => String, :barcode_prefixes => Array}

      # Initilize the SequencescapePlateCreator class
      # @param [String] queue name
      # @param [Hash] AMQP settings
      # @param [Hash] bridge settings
      def initialize(amqp_settings, mysql_settings, bridge_settings)
        @queue_name = amqp_settings.delete("plate_creator_queue_name") 
        @bus = MessageBus.new(amqp_settings.delete("sequencescape").first)
        @settings = bridge_settings
        consumer_setup(amqp_settings)
        sequencescape_db_setup(mysql_settings)
        set_queue
      end

      # @param [Logger] logger
      def set_logger(logger)
        @log = logger
      end

      private

      # Setup the Sequencescape database connection
      # @param [Hash] MySQL settings
      def sequencescape_db_setup(settings = {})
        @db = Sequel.connect(settings) unless settings.empty?
      end 

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
          handler_class = PlateCreator::MessageHandler.const_get(klass)  
          handler_class.new(db, bus, log, metadata, s2_resource, settings)
        end

        case metadata.routing_key
        # Plate and tuberack are stored in the same place in sequencescape
        when /(plate|tuberack)\.create/ then handler_for[:plate].call
          # On reception of an order creation/update message
        when /order\.(create|updateorder)/ then handler_for[:order].call
          # On reception of a plate transfer message
        when /platetransfer|transferplatestoplates|updatetuberack|tuberacktransfer/ then handler_for[:update_aliquots].call
          # Tube rack move messages have a custom handler as it needs to delete aliquots in the source racks.
        when /tuberackmove/ then handler_for[:tube_rack_move].call
        when /deletetuberack/ then handler_for[:plate_delete].call
        when /labellable/ then handler_for[:labellable].call
        when /swapsamples/ then handler_for[:swap_samples].call
        end
      end
    end
  end
end
