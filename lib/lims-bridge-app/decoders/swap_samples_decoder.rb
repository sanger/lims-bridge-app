require 'lims-bridge-app/base_decoder'
require 'lims-bridge-app/decoders/plate_decoder'
require 'lims-bridge-app/decoders/tube_rack_decoder'

module Lims::BridgeApp
  module Decoders
    class SwapSamplesDecoder < BaseDecoder

      private

      # @return [Hash]
      def decode_swap_samples
        resources = [].tap do |r|
          resource_hash["result"].each do |resource|
            model = resource.keys.first
            decoder_class = case model
                            when "tube_rack" then TubeRackDecoder
                            when "plate" then PlateDecoder
                            end
            r << decoder_class.new(resource, options).call if decoder 
          end
        end

        {:resources => resources, :swaps => resource_hash["parameters"]}
      end
    end
  end
end
