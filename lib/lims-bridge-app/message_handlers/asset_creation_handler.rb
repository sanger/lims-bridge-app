require 'lims-bridge-app/base_handler'

module Lims::BridgeApp
  module MessageHandlers
    class AssetCreationHandler < BaseHandler

      def _call_in_transaction
        begin 
          asset_uuid = resource[:uuid]
          sample_uuids = resource[:sample_uuids]
          container = resource[resource.keys.first]
          sequencescape.date = resource[:date]

          sequencescape.create_asset(container, container_uuid, sample_uuids).tap do |asset_id|
            sequencescape.create_uuid(settings["asset_type"], asset_id, asset_uuid)
            sequencescape.create_location(asset_id)
            bus.publish(asset_uuid) 
          end
        rescue Sequel::Rollback, UnknownSample, InvalidContainer => e
          metadata.reject(:requeue => true)
          log.info("Error creating asset in Sequencescape: #{e}")
          # Need to reraise a rollback exception as we are still 
          # in a sequel transaction block.
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Asset created in Sequencescape and message acknowledged")
        end
      end
      private :_call_in_transaction
    end
  end
end
