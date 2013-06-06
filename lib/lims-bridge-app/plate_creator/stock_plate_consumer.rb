require 'lims-busclient'
require 'lims-bridge-app/plate_creator/json_decoder'
require 'lims-bridge-app/plate_creator/sequencescape_updater'
require 'lims-bridge-app/plate_creator/message_handlers/all'
require 'lims-bridge-app/s2_resource'

require 'rubygems'
require 'ruby-debug/debugger'

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

      attribute :queue_name, String, :required => true, :writer => :private, :reader => :private
      attribute :log, Object, :required => false, :writer => :private
      attribute :routing_keys, Array, :required => false, :writer => :private
      attribute :db, Sequel::MySQL::Database, :required => true, :writer => :private, :reader => :private

      EXPECTED_ROUTING_KEYS_PATTERNS = [
        '*.*.plate.create',
        '*.*.tuberack.create',
        '*.*.tuberack.updatetuberack',
        '*.*.order.create',
        '*.*.order.updateorder',
        '*.*.platetransfer.platetransfer',
        '*.*.transferplatestoplates.transferplatestoplates',
        '*.*.tuberacktransfer.tuberacktransfer',
        '*.*.tuberackmove.tuberackmove'
      ].map { |k| Regexp.new(k.gsub(/\./, "\\.").gsub(/\*/, ".*")) }

      # Initilize the SequencescapePlateCreator class
      # @param [String] queue name
      # @param [Hash] AMQP settings
      def initialize(amqp_settings, mysql_settings)
        @queue_name = amqp_settings.delete("plate_creator_queue_name") 
        @routing_keys = amqp_settings.delete("routing_keys")
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
        unless settings.empty?
          @db = Sequel.connect(:adapter => settings['adapter'],
                               :host => settings['host'],
                               :user => settings['user'],
                               :password => settings['password'],
                               :database => settings['database'])
        end
      end 

      # @param [String] routing_key
      # @return [Bool]
      def expected_message?(routing_key)
        EXPECTED_ROUTING_KEYS_PATTERNS.each do |pattern|
          return true if routing_key.match(pattern)
        end
        false
      end

      # Setup the queue.
      # 3 different behaviours depending on the routing key
      # of the message (plate/plate_transfer/order). 
      def set_queue
        self.add_queue(queue_name, routing_keys) do |metadata, payload|
          log.info("Message received with the routing key: #{metadata.routing_key}")
          if expected_message?(metadata.routing_key)
            log.debug("Processing message with routing key: '#{metadata.routing_key}' and payload: #{payload}")
            s2_resource = s2_resource(payload)
            routing_message(metadata, s2_resource)
          else
            metadata.reject
            log.debug("Message rejected: unexpected message (routing key: #{metadata.routing_key})")
          end
        end
      end

      # @param [AMQP::Header] metadata
      # @param [Hash] s2_resource
      # Route the message to the correct handler method
      def routing_message(metadata, s2_resource)
        handler_for = lambda do |type|
          klass = "#{type.to_s.capitalize.gsub(/_./) {|p| p[1].upcase}}Handler"         
          handler_class = PlateCreator::MessageHandler.const_get(klass)  
          handler_class.new(db, log, metadata, s2_resource)
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
        end
      end
    end
  end
end
