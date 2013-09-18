require 'lims-bridge-app/plate_management/base_handler'

module Lims::BridgeApp::PlateManagement
  module MessageHandler
    class UpdateAliquotsHandler < BaseHandler

      private

      # For an update message, we update the plate in sequencescape 
      # setting the updated aliquots.
      # @param [AMQP::Header] metadata
      # @param [Hash] s2 resource
      def _call_in_transaction
        begin
          update_aliquots(s2_resource)
        rescue Sequel::Rollback, PlateNotFoundInSequencescape, UnknownSample => e
          metadata.reject(:requeue => true)
          log.info("Error updating plate aliquots in Sequencescape: #{e}")
          raise Sequel::Rollback
        rescue TransferRequestNotFound => e
          metadata.ack
          log.info("Plate update message processed and acknowledged with the warning: #{e}")
        else
          metadata.ack
          log.info("Plate update message processed and acknowledged")
        end
      end

      # @param [Lims::LaboratoryApp::Laboratory::Plate] plate
      def update_aliquots(plate)
        plate_uuid = plate[:uuid]
        update_aliquots_in_sequencescape(plate[:plate], plate_uuid, plate[:date], plate[:sample_uuids])
        bus.publish(plate_uuid)
      end
    end
  end
end
