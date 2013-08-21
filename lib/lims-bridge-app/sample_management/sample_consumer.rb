require 'lims-busclient'
require 'lims-bridge-app/sample_management/sequencescape_updater'
require 'lims-bridge-app/sample_management/json_decoder'
require 'lims-bridge-app/message_bus'
require 'lims-bridge-app/base_consumer'

module Lims::BridgeApp
  module SampleManagement
    class SampleConsumer < BaseConsumer
      include SequencescapeUpdater

      SETTINGS = {:sample_type => String, :study_sample_type => String}

      # @param [Hash] amqp_settings
      # @param [Hash] mysql_settings
      # @param [Hash] bridge_settings
      def initialize(amqp_settings, mysql_settings, bridge_settings)
        @queue_name = amqp_settings.delete("sample_queue_name")
        super(amqp_settings, mysql_settings, bridge_settings)
      end

      private

      # If the message is an expected message, we get the 
      # corresponding s2 resource from the message json, then
      # pass it to the sample message handler for processing.
      def set_queue
        self.add_queue(queue_name) do |metadata, payload|
          log.info("Message received with the routing key: #{metadata.routing_key}")

          log.debug("Processing message with routing key: '#{metadata.routing_key}' and payload: #{payload}")
          s2_resource = s2_resource(payload)
          action = case metadata.routing_key
                   when /sample\.create|bulkcreatesample/ then "create"
                   when /sample\.updatesample|bulkupdatesample/ then "update"
                   when /sample\.deletesample|bulkdeletesample/ then "delete"
                   end

          sample_message_handler(metadata, s2_resource, action)
        end
      end

      # @param [AMQP::Header] metadata
      # @param [Hash] s2_resource
      # @param [String] action
      # If the message is about a bulk action, each sample needs
      # to be processed by the dispatch_s2_sample_in_sequencescape method.
      # If an update or delete message arrives before a sample is created,
      # an exception UnknownSample is raised and the message are requeue
      # waiting the message to create the sample arrives.
      def sample_message_handler(metadata, s2_resource, action)
        begin
          if s2_resource[:samples]
            s2_resource[:samples].each do |h|
              sample_uuid = h[:uuid]
              dispatch_s2_sample_in_sequencescape(h[:sample], sample_uuid, h[:date], action)
              bus.publish(sample_uuid)
            end
          else
            sample_uuid = s2_resource[:uuid]
            dispatch_s2_sample_in_sequencescape(s2_resource[:sample], sample_uuid, s2_resource[:date], action)
            bus.publish(sample_uuid)
          end
        rescue Sequel::Rollback, UnknownSample => e
          metadata.reject(:requeue => true)
          log.info("Error saving sample in Sequencescape: #{e}")
        rescue UnknownStudy => e
          metadata.reject
          log.error("Error saving sample in Sequencescape: #{e}")
        else
          metadata.ack
          log.info("Sample message processed and acknowledged")
        end
      end
    end
  end
end
