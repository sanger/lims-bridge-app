require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-bridge-app/decoders/tube_rack_decoder'

module Lims::BridgeApp
  module Decoders
    class TubeRackMoveDecoder < BaseDecoder

      private

      # @return [Hash]
      def decode_tube_rack_move
        {:moves => resource_hash["moves"]}
      end
    end
  end
end
