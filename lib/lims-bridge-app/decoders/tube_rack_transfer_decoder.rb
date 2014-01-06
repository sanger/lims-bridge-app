require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-bridge-app/decoders/tube_rack_decoder'
require 'lims-bridge-app/decoders/single_transfer_shared'

module Lims::BridgeApp
  module Decoders
    class TubeRackTransferDecoder < BaseDecoder

      include SingleTransferShared

      private

      # @return [Hash]
      def decode_tube_rack_transfer
        _decode_transfer("tube_rack", TubeRackDecoder)
      end
    end
  end
end
