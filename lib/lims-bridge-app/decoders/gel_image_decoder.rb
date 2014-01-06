require 'lims-bridge-app/base_decoder'
require 'lims-quality-app/gel-image/gel_image'

module Lims::BridgeApp
  module Decoders
    class GelImageDecoder < BaseDecoder

      private

      # @return [Lims::QualityApp::GelImage]
      def decode_gel_image
        Lims::QualityApp::GelImage.new({
          :gel_uuid => resource_hash["gel_uuid"],
          :scores => resource_hash["scores"]
        })
      end

      # @return [Lims::QualityApp::GelImage]
      def decode_update_gel_image_scores
        @payload = resource_hash["result"]
        decode_gel_image
      end
    end
  end
end
