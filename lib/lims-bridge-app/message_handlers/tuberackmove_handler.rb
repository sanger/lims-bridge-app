require 'lims-bridge-app/base_handler'

module Lims::BridgeApp
  module MessageHandlers
    class TubeRackMoveHandler < BaseHandler

      def _call_in_transaction
        begin
          resource[:moves].each do |move|
            source_uuid = move["source_uuid"]
            target_uuid = move["target_uuid"]
            source_location, target_location = move["source_location"], move["target_location"]

            sequencescape.move_well(source_uuid, source_location, target_uuid, target_location)

            bus.publish(source_uuid)
            bus.publish(target_uuid)
          end
        rescue SequencescapeWrapper::AssetNotFound => e
          metadata.reject(:requeue => true)
          log.info("Error moving plates in Sequencescape: #{e}")
        else
          metadata.ack
          log.info("Tube rack move message processed and acknowledged")
        end
      end 
      private :_call_in_transaction
    end
  end
end
