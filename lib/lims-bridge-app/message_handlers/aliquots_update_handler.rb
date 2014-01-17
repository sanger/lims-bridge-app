require 'lims-bridge-app/base_handler'

module Lims::BridgeApp
  module MessageHandlers
    class AliquotsUpdateHandler < BaseHandler

      # For an update message, we update the plate in sequencescape 
      # setting the updated aliquots.
      def _call_in_transaction
        begin
          update_aliquots
        rescue Sequel::Rollback, SequencescapeWrapper::AssetNotFound, SequencescapeWrapper::UnknownSample => e
          metadata.reject(:requeue => true)
          log.info("Error updating plate aliquots in Sequencescape: #{e}")
          raise Sequel::Rollback
        rescue SequencescapeWrapper::TransferRequestNotFound => e
          metadata.ack
          log.info("Plate update message processed and acknowledged with the warning: #{e}")
        else
          metadata.ack
          log.info("Plate update message processed and acknowledged")
        end
      end
      private :_call_in_transaction

      def update_aliquots
        asset_uuid = resource[:uuid]
        asset = resource[resource.keys.first]
        sample_uuids = resource[:sample_uuids]
        sequencescape.update_aliquots(asset, asset_uuid, sample_uuids)
        bus.publish(asset_uuid)
      end
    end
  end
end
