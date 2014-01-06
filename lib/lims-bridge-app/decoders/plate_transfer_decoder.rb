require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-bridge-app/decoders/plate_decoder'
require 'lims-bridge-app/decoders/single_transfer_shared'

module Lims::BridgeApp
  module Decoders
    class PlateTransferDecoder < BaseDecoder

      include SingleTransferShared

      private

      # @return [Hash]
      def decode_plate_transfer
        _decode_transfer("plate", PlateDecoder)
      end
    end
  end
end
