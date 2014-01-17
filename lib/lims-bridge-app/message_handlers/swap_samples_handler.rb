require 'lims-bridge-app/base_handler'

module Lims::BridgeApp
  module MessageHandlers
    class SwapSamplesHandler < BaseHandler

      private

      def _call_in_transaction
        begin
          resource[:resources].each do |resource|
            asset_uuid = resource[:uuid]
            asset_sample_uuids = resource[:sample_uuids]
            swaps = swaps_for(asset_uuid) 

            sequencescape.swap_samples(asset_uuid, asset_sample_uuids, swaps)
            bus.publish(asset_uuid)
          end
        rescue Sequel::Rollback, SequencescapeWrapper::AssetNotFound, SequencescapeWrapper::UnknownSample => e
          metadata.reject(:requeue => true)
          log.info("Error swapping samples in Sequencescape: #{e}")
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Swap sample message processed and acknowledged")
        end
      end

      # @param [String] asset_uuid
      # @return [Hash]
      def swaps_for(asset_uuid)
        resource[:swaps].each do |swap_parameters|
          return swap_parameters["swaps"] if swap_parameters["resource_uuid"] == asset_uuid
        end
      end
    end
  end
end
