require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-bridge-app/decoders/plate_like_shared'

module Lims::BridgeApp
  module Decoders
    class PlateDecoder < BaseDecoder

      include PlateLikeShared

      private

      # @return [Hash]
      def decode_plate
        plate = _decode(@payload, "plate", "wells")
        sample_uuids = _sample_uuids(@payload["plate"]["wells"])
        {:plate => plate, :sample_uuids => sample_uuids} 
      end
    end
  end
end
