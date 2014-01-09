require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-bridge-app/decoders/plate_like_shared'
require 'lims-bridge-app/decoders/single_transfer_shared'

module Lims::BridgeApp
  module Decoders
    class PlateDecoder < BaseDecoder
      include PlateLikeShared

      private

      # @return [Hash]
      def decode_plate
        plate = _decode(@payload, "wells")
        sample_uuids = _sample_uuids(@payload["plate"]["wells"])
        {:plate => plate, :sample_uuids => sample_uuids} 
      end
    end

    class PlateTransferDecoder < PlateDecoder
      include SingleTransferShared

      private

      # @return [Hash]
      def decode_plate_transfer
        _decode_transfer("plate", PlateDecoder)
      end
    end
  end
end
