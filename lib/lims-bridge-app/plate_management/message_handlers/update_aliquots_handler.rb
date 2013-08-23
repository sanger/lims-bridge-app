require 'lims-bridge-app/plate_management/base_handler'

module Lims::BridgeApp::PlateManagement
  module MessageHandler
    class UpdateAliquotsHandler < BaseHandler

      private

      # When a plate transfer message is received,
      # or an update message,
      # we update the target plate in sequencescape 
      # setting the transfered aliquots.
      # @param [AMQP::Header] metadata
      # @param [Hash] s2 resource
      def _call_in_transaction
        begin
          if s2_resource.has_key?(:plates)
            s2_resource[:plates].each do |plate|
              plate_uuid = plate[:uuid]
              update_aliquots_in_sequencescape(plate[:plate], plate_uuid, plate[:date], plate[:sample_uuids])
              bus.publish(plate_uuid)
            end
          else
            plate_uuid = s2_resource[:uuid]
            update_aliquots_in_sequencescape(s2_resource[:plate], plate_uuid, s2_resource[:date], s2_resource[:sample_uuids])
            bus.publish(plate_uuid)
          end
        rescue Sequel::Rollback, PlateNotFoundInSequencescape => e
          metadata.reject(:requeue => true)
          log.info("Error updating plate aliquots in Sequencescape: #{e}")
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Plate transfer message processed and acknowledged")
        end
      end
    end
  end
end
