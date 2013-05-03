require 'lims-busclient'
require 'lims-bridge-app/sample/sequencescape_updater'
require 'lims-bridge-app/s2_resource'
require 'lims-bridge-app/sample/json_decoder'

module Lims::BridgeApp
  module SampleManagement
    class SampleConsumer
      include Lims::BusClient::Consumer
      include SequencescapeUpdater
      include S2Resource
      include JsonDecoder

      attribute :queue_name, String, :required => true, :writer => :private, :reader => :private
      attribute :log, Object, :required => false, :writer => :private

      EXPECTED_ROUTING_KEYS_PATTERNS = [
        '*.*.sample.create',
        '*.*.sample.updatesample',
        '*.*.sample.deletesample',
        '*.*.bulkcreatesample.*'
      ].map { |k| Regexp.new(k.gsub(/\./, "\\.").gsub(/\*/, ".*")) }

      def initialize(amqp_settings, mysql_settings)
        @queue_name = amqp_settings.delete("queue_name")
        consumer_setup(amqp_settings)
        sequencescape_db_setup(mysql_settings)
        set_queue
      end

      def set_logger(logger)
        @log = logger
      end

      private

      def expected_message?(routing_key)
        EXPECTED_ROUTING_KEYS_PATTERNS.each do |pattern|
          return true if routing_key.match(pattern)
        end
        false
      end

      def set_queue
        self.add_queue(queue_name) do |metadata, payload|
          log.info("Message received with the routing key: #{metadata.routing_key}")
          if expected_message?(metadata.routing_key)
            log.debug("Processing message with routing key: '#{metadata.routing_key}' and payload: #{payload}")
            s2_resource = s2_resource(payload)

            message_handler = case metadata.routing_key
                              when /sample\.create/ then {:method => :sample_message_handler, :action => "create"}
                              when /sample\.updatesample/ then {:method => :sample_message_handler, :action => "udpate"}
                              when /sample\.deletesample/ then {:method => :sample_message_handler, :action => "delete"}
                              when /bulkcreatesample/ then {:method => :bulk_create_sample_message_handler, :action => nil}
                              else {}
                              end
            send(message_handler[:method], metadata, s2_resource, message_handler[:action])
          else
            metadata.reject
            log.debug("Message rejected: unused message (routing key: #{metadata.routing_key})")
          end
        end
      end

      def sample_message_handler(metadata, s2_resource, action)
        begin
          dispatch_s2_sample_in_sequencescape(s2_resource[:sample], s2_resource[:uuid], action)
        rescue Sequel::Rollback => e
          metadata.reject(:requeue => true)
          log.error("Error saving sample in Sequencescape: #{e}")
        else
          metadata.ack
          log.info("Sample message processed and acknowledged")
        end
      end

      def bulk_create_sample_message_handler(metadata, s2_resource)
        begin
          s2_resource[:samples].each do |h|
            dispatch_s2_sample_in_sequencescape(h[:sample], h[:uuid])
          end
        rescue Sequel::Rollback => e
          metadata.reject(:requeue => true)
          log.error("Error saving samples in Sequencescape: #{e}")
        else
          metadata.ack
          log.info("Bulk create sample message processed and acknowledged")
        end
      end
    end
  end
end
