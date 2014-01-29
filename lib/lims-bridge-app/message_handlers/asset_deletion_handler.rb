require 'lims-bridge-app/base_handler'

module Lims::BridgeApp
  module MessageHandlers
    class AssetDeletionHandler < BaseHandler

      def _call_in_transaction
        begin 
          asset_uuid = resource[:uuid]
          sequencescape.delete_asset(asset_uuid)
          bus.publish(asset_uuid)
        rescue Sequel::Rollback, SequencescapeWrapper::AssetNotFound => e
          metadata.reject(:requeue => true)
          log.info("Error deleting asset in Sequencescape: #{e}")
          # Need to reraise a rollback exception as we are still 
          # in a sequel transaction block.
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Message processed and acknowledged")
        end
      end
      private :_call_in_transaction
    end
  end
end
