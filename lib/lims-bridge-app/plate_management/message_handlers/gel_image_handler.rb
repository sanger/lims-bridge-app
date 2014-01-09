require 'lims-bridge-app/plate_management/base_handler'
require 'rubygems'
require 'ruby-debug/debugger'

module Lims::BridgeApp::PlateManagement
  module MessageHandler
    class GelImageHandler < BaseHandler

      private

      def _call_in_transaction
        begin
          update_gel_scores(s2_resource[:gel_image], s2_resource[:date])
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
