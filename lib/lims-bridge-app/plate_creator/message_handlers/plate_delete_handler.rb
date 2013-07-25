require 'lims-bridge-app/plate_creator/base_handler'

module Lims::BridgeApp::PlateCreator
  module MessageHandler
    class PlateDeleteHandler < BaseHandler

      private

      def _call_in_transaction
        begin 
          plate_uuid = s2_resource[:uuid]
          delete_plate(plate_uuid)
          bus.publish(plate_uuid)
        rescue Sequel::Rollback, PlateNotFoundInSequencescape => e
          metadata.reject(:requeue => true)
          log.info("Error deleting plate in Sequencescape: #{e}")
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
