require 'lims-bridge-app/base_handler'

module Lims::BridgeApp
  module MessageHandlers
    class LabellableHandler < BaseHandler

      def _call_in_transaction
        begin 
          if resource.has_key?(:labellables)
            resource[:labellables].each do |labellable|
              sequencescape.barcode_an_asset(labellable)
              asset_uuid = labellable.name
              bus.publish(asset_uuid)
            end
          else
            sequencescape.barcode_an_asset(resource[:labellable])
            asset_uuid = resource[:labellable].name
            bus.publish(asset_uuid)
          end
        rescue Sequel::Rollback, SequencescapeWrapper::AssetNotFound => e
          metadata.reject(:requeue => true)
          log.info("Error updating barcode in Sequencescape: #{e}")
          # Need to reraise a rollback exception as we are still 
          # in a sequel transaction block.
          raise Sequel::Rollback
        rescue SequencescapeWrapper::InvalidBarcode => e
          metadata.reject
          log.info("Error updating barcode in Sequencescape: #{e}")
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Labellable message processed and acknowledged")
        end
      end
      private :_call_in_transaction
    end
  end
end
