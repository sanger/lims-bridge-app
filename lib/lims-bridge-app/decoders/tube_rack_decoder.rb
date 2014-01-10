require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-bridge-app/decoders/single_transfer_shared'

module Lims::BridgeApp
  module Decoders
    class TubeRackDecoder < BaseDecoder

      private

      # @return [Hash]
      def decode_tube_rack
        plate = Lims::LaboratoryApp::Laboratory::Plate.new({:number_of_rows => resource_hash["number_of_rows"],
                                                            :number_of_columns => resource_hash["number_of_columns"]})
        resource_hash["tubes"].each do |location, tube|
          tube["aliquots"].each do |aliquot|
            plate[location] << Lims::LaboratoryApp::Laboratory::Aliquot.new({
              :quantity => aliquot["quantity"],
              :type => aliquot["type"]
            })
          end
        end

        {:plate => plate, :sample_uuids => _sample_uuids(resource_hash["tubes"])}
      end

      # Get the sample uuids in the tuberack
      # The location returned is the location of the tube
      # with all its corresponding sample uuids.
      # @param [Hash] tubes
      # @return [Hash] sample uuids
      # @example
      # {"A1" => ["sample_uuid1", "sample_uuid2"]} 
      def _sample_uuids(tubes)
        {}.tap do |uuids|
          tubes.each do |location, tube|
            tube["aliquots"].each do |aliquot|
              uuids[location] ||= []
              uuids[location] << aliquot["sample"]["uuid"] if aliquot["sample"]
            end
          end
        end
      end
    end


    class TubeRackMoveDecoder < TubeRackDecoder
      # @return [Hash]
      def decode_tube_rack_move
        {:moves => resource_hash["moves"]}
      end
      private :decode_tube_rack_move
    end


    class TubeRackTransferDecoder < TubeRackDecoder
      include SingleTransferShared

      # @return [Hash]
      def decode_tube_rack_transfer
        _decode_transfer("tube_rack", TubeRackDecoder)
      end
      private :decode_tube_rack_transfer
    end
  end
end
