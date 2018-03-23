require 'lims-bridge-app/plate_management/base_handler'

module Lims::BridgeApp::PlateManagement
  module MessageHandler
    class SwapSamplesHandler < BaseHandler

      private

      def _call_in_transaction
        begin
          s2_resource[:resources].each do |resource|
            plate_uuid = resource[:uuid]
            location_samples = resource[:sample_uuids]
            date = resource[:date]
            swaps = swaps_for(plate_uuid) 

            swap_samples(plate_uuid, location_samples, swaps, date)
            bus.publish(plate_uuid)
          end
        rescue Sequel::Rollback, PlateNotFoundInSequencescape, UnknownSample => e
          metadata.reject(:requeue => true)
          log.info("Error swapping samples in Sequencescape: #{e}")
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Swap sample message processed and acknowledged")
        end
      end

      # @param [String] plate_uuid
      # @return [Hash]
      def swaps_for(plate_uuid)
        s2_resource[:swaps].each do |swap_parameters|
          return swap_parameters["swaps"] if swap_parameters["resource_uuid"] == plate_uuid
        end
      end
    end
  end
end
