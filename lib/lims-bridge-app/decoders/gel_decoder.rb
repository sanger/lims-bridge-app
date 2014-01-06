require 'lims-laboratory-app/laboratory/gel'
require 'lims-bridge-app/base_decoder'
require 'lims-bridge-app/decoders/plate_like_shared'

module Lims::BridgeApp
  module Decoders
    class GelDecoder < BaseDecoder

      include PlateLikeShared

      private

      # Gel behaves like plate in Sequencescape
      # @return [Hash]
      def decode_gel
        plate = _decode(@payload, "gel", "windows") 
        sample_uuids = _sample_uuids(@payload["gel"]["windows"])
        {:plate => plate, :sample_uuids => sample_uuids} 
      end
    end
  end
end
