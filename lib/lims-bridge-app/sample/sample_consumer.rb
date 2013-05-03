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

            action = case metadata.routing_key
                     when /sample\.create/ || /bulkcreatesample/ then "create"
                     when /sample\.updatesample/ then "udpate"
                     when /sample\.deletesample/ then "delete"
                     end

            sample_message_handler(metadata, s2_resource, action) do |s2_resource|
              if s2_resource[:samples]
                s2_resource[:samples].each do |h|
                  dispatch_s2_sample_in_sequencescape(h[:sample], h[:uuid], action)
                end
              else
                dispatch_s2_sample_in_sequencescape(s2_resource[:sample], s2_resource[:uuid], action)
              end
            end
          else
            metadata.reject
            log.debug("Message rejected: unused message (routing key: #{metadata.routing_key})")
          end
        end
      end

      def sample_message_handler(metadata, s2_resource, action)
        begin
          yield(s2_resource)
        rescue Sequel::Rollback => e
          metadata.reject(:requeue => true)
          log.error("Error saving sample in Sequencescape: #{e}")
        else
          metadata.ack
          log.info("Sample message processed and acknowledged")
        end
      end
    end
  end
end
