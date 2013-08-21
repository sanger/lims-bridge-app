require 'lims-bridge-app/plate_management/base_handler'

module Lims::BridgeApp::PlateManagement
  module MessageHandler
    class PlateHandler < BaseHandler

      private

      # When a plate creation message is received, 
      # the plate is created in Sequencescape database.
      # If everything goes right, the message is acknowledged.
      # @param [AMQP::Header] metadata
      # @param [Hash] s2 resource 
      # @example
      # {:plate => Lims::Core::Laboratory::Plate, :uuid => xxxx}
      def _call_in_transaction
        begin 
          plate_uuid = s2_resource[:uuid]
          create_plate_in_sequencescape(s2_resource[:plate], plate_uuid, s2_resource[:date], s2_resource[:sample_uuids])
          bus.publish(plate_uuid) 
        rescue Sequel::Rollback, UnknownSample => e
          metadata.reject(:requeue => true)
          log.info("Error saving plate in Sequencescape: #{e}")
          # Need to reraise a rollback exception as we are still 
          # in a sequel transaction block.
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Plate message processed and acknowledged")
        end
      end
    end
  end
end
