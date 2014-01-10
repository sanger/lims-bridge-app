require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-bridge-app/decoders/plate_like_shared'
require 'lims-bridge-app/decoders/single_transfer_shared'
require 'lims-bridge-app/decoders/gel_decoder'
require 'lims-bridge-app/decoders/tube_rack_decoder'

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


    class TransferPlatesToPlatesDecoder < PlateDecoder

      private

      # @return [Hash]
      def decode_transfer_plates_to_plates
        plates = []
        ["sources", "targets"].each do |key|
          resource_hash["result"][key].each do |asset|
            asset_decoder = case asset.keys.first
                            when "plate" then PlateDecoder.new(asset, options)
                            when "tube_rack" then TubeRackDecoder.new(asset, options)
                            when "gel" then GelDecoder.new(asset, options)
                            end

            plates << asset_decoder.call
          end
        end

        {:plates => plates, :transfer_map => resource_hash["transfers"]}
      end
    end
  end
end
