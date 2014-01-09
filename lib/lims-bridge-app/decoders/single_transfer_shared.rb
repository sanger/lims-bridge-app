module Lims::BridgeApp
  module Decoders
    module SingleTransferShared

      # @param [String] model
      # @param [Class] decoder_class
      def _decode_transfer(model, decoder_class)
        transfer_map = [].tap do |t|
          source_uuid = resource_hash["source"][model]["uuid"]
          target_uuid = resource_hash["target"][model]["uuid"]
          resource_hash["transfer_map"].each do |source_location, target_location|
            t << {
              "source_uuid" => source_uuid, "source_location" => source_location, 
              "target_uuid" => target_uuid, "target_location" => target_location
            }
          end
        end

        plates = [].tap do |p|
          ["source", "target"].each do |key|
            p << decoder_class.new(resource_hash[key], @options).call
          end
        end

        {:plates => plates, :transfer_map => transfer_map}
      end
    end
  end
end
