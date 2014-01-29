require 'lims-bridge-app/base_handler'

module Lims::BridgeApp
  module MessageHandlers
    class GelImageHandler < BaseHandler

      def _call_in_transaction
        begin
          gel_image = resource[:gel_image]
          sequencescape.update_gel_scores(gel_image)
        rescue SequencescapeWrapper::AssetNotFound => e
          metadata.reject(:requeue => true)
          log.info("Error updating gel score in Sequencescape: #{e}")
          raise Sequel::Rollback
        rescue SequencescapeWrapper::UnknownLocation => e
          metadata.reject
          log.error("Error updating gel score in Sequencescape: #{e}")
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Plate message processed and acknowledged")
        end
      end
      private :_call_in_transaction
    end
  end
end
