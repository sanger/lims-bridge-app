require 'lims-bridge-app/plate_management/base_handler'

module Lims::BridgeApp::PlateManagement
  module MessageHandler
    class TransferHandler < BaseHandler

      private

      # When a plate transfer message is received, we update the aliquots
      # of the plates involved in the transfer and then, add a row for the
      # transfer request in the requests table.
      # @param [AMQP::Header] metadata
      # @param [Hash] s2 resource
      def _call_in_transaction
        aliquot_updater = UpdateAliquotsHandler.new(db, bus, log, metadata, s2_resource, settings)

        begin 
          s2_resource[:plates].each do |plate|
            aliquot_updater.send(:update_aliquots, plate)
          end
          date = s2_resource[:plates].first[:date]
          add_asset_links(s2_resource[:transfer_map], date)
          set_transfer_requests(s2_resource[:transfer_map], date)
        rescue Sequel::Rollback, PlateNotFoundInSequencescape, UnknownSample => e
          metadata.reject(:requeue => true)
          log.info("Error updating plate aliquots in Sequencescape: #{e}")
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Plate transfer message processed and acknowledged")
        end
      end

      def add_asset_links(transfer_map, date)
        asset_link_set = Set.new(transfer_map.map do |transfer|
            {:ancestor_id    => plate_id_by_uuid(transfer["source_uuid"]),
              :descendant_id  => plate_id_by_uuid(transfer["target_uuid"]),
              :direct         => 1,
              :count          => 1,
              :created_at     => date,
              :updated_at     => date }
          end
        )

        set_asset_link(asset_link_set)

      end

      # @param [Hash] transfer_map
      # @param [Time] date
      def set_transfer_requests(transfer_map, date)
        transfer_map.each do |transfer|
          source_uuid = transfer["source_uuid"]
          source_location = transfer["source_location"]
          target_uuid = transfer["target_uuid"]
          target_location = transfer["target_location"]

          source_id = plate_id_by_uuid(source_uuid)
          target_id = plate_id_by_uuid(target_uuid)

          source_well_id = well_id_by_location(source_id, source_location)
          target_well_id = well_id_by_location(target_id, target_location)

          create_transfer_request!(source_well_id, target_well_id, date) 
        end
      end
    end
  end
end
