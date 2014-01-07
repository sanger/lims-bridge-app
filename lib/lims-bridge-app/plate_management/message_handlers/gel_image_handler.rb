require 'lims-bridge-app/plate_management/base_handler'

module Lims::BridgeApp::PlateManagement
  module MessageHandler
    class GelImageHandler < BaseHandler

      private

      def _call_in_transaction
        begin
          update_gel_scores(s2_resource[:gel_image])          
        rescue PlateNotFoundInSequencescape => e
          metadata.reject(:requeue => true)
          log.info("Error updating gel score in Sequencescape: #{e}")
        rescue UnknownLocation => e
          metadata.reject
          log.error("Error updating gel score in Sequencescape: #{e}")
        else
          metadata.ack
          log.info("Plate message processed and acknowledged")
        end
      end
    end
  end
end
