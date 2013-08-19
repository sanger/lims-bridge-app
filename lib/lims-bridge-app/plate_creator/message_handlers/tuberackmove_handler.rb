require 'lims-bridge-app/plate_creator/message_handlers/update_aliquots_handler'
require 'lims-bridge-app/plate_creator/base_handler'

module Lims::BridgeApp::PlateCreator
  module MessageHandler
    class TubeRackMoveHandler < BaseHandler

      private

      def _call_in_transaction
        moves = s2_resource.delete(:moves)
        date = s2_resource.delete(:date)

        begin
          moves.each do |move|
            move_wells_in_sequencescape(move, date)

            bus.publish(move["source_uuid"])
            bus.publish(move["target_uuid"])
          end
        rescue PlateNotFoundInSequencescape => e
          metadata.reject(:requeue => true)
          log.info("Error moving plates in Sequencescape: #{e}")
        else
          metadata.ack
          log.info("Tube rack move message processed and acknowledged")
        end
      end 
    end
  end
end
