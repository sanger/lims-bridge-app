require 'lims-bridge-app/plate_creator/message_handlers/update_aliquots_handler'
require 'lims-bridge-app/plate_creator/base_handler'

module Lims::BridgeApp::PlateCreator
  module MessageHandler
    class TubeRackMoveHandler < BaseHandler

      private

      def _call_in_transaction
        source_locations = s2_resource.delete(:source_locations)
        delete_aliquots_in_sequencescape(source_locations)
        source_locations.each { |plate_uuid, _| bus.publish(plate_uuid) }

        UpdateAliquotsHandler.new(db, bus, log, metadata, s2_resource).call
      end 
    end
  end
end
