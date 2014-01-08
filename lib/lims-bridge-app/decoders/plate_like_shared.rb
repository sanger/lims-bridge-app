require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/laboratory/aliquot'

module Lims::BridgeApp
  module Decoders
    module PlateLikeShared

      # @param [Hash] payload
      # @param [String] model_name
      # @param [String] receptacle_name
      # @return [Plate]
      def _decode(payload, receptacle_name)
        Lims::LaboratoryApp::Laboratory::Plate.new({
          :number_of_rows => resource_hash["number_of_rows"],
          :number_of_columns => resource_hash["number_of_columns"]
        }).tap do |p|
          resource_hash[receptacle_name.to_s].each do |location, aliquots|
            unless aliquots.empty?
              aliquots.each do |aliquot|
                p[location] << Lims::LaboratoryApp::Laboratory::Aliquot.new({
                  :quantity => aliquot["quantity"],
                  :type => aliquot["type"],
                  :out_of_bounds => aliquot["out_of_bounds"] || {}
                })
              end
            end
          end
        end
      end

      # Get the sample uuids in the plate
      # @param [Hash] wells
      # @return [Hash] sample uuids
      # @example
      # {"A1" => ["sample_uuid1", "sample_uuid2"]} 
      def _sample_uuids(wells)
        {}.tap do |uuids|
          wells.each do |location, aliquots|
            unless aliquots.empty?
              aliquots.each do |aliquot|
                uuids[location] ||= []
                uuids[location] << aliquot["sample"]["uuid"] if aliquot["sample"]
              end
            end
          end
        end
      end
    end
  end
end
