require 'lims-bridge-app/base_handler'
require 'lims-bridge-app/message_handlers/aliquots_update_handler'

module Lims::BridgeApp
  module MessageHandlers
    class TransferHandler < BaseHandler

      private

      # When a transfer message is received, we update the aliquots
      # of the resources involved in the transfer and then, add a row for the
      # transfer request in the requests table.
      def _call_in_transaction
        begin
          resource[:plates].each do |plate|
            aliquots_update_handler = AliquotsUpdateHandler.new(bus, log, metadata, plate, settings) 
            aliquots_update_handler.update_aliquots
          end

          resource[:transfer_map].each do |transfer| 
            source_uuid, target_uuid = transfer["source_uuid"], transfer["target_uuid"]
            source_location, target_location = transfer["source_location"], transfer["target_location"]
            source_id = sequencescape.asset_id_by_uuid(source_uuid)
            target_id = sequencescape.asset_id_by_uuid(target_uuid)
            source_well_id = sequencescape.well_id_by_location(source_id, source_location) 
            target_well_id = sequencescape.well_id_by_location(target_id, target_location)

            sequencescape.create_asset_link(source_id, target_id)
            sequencescape.create_transfer_request(source_well_id, target_well_id)
          end

        rescue Sequel::Rollback, SequencescapeWrapper::AssetNotFound, SequencescapeWrapper::UnknownSample => e
          metadata.reject(:requeue => true)
          log.info("Error plate aliquots in Sequencescape: #{e}")
          raise Sequel::Rollback

        else
          metadata.ack
          log.info("Transfer message processed and acknowledged")
        end
      end

    end
  end
end
